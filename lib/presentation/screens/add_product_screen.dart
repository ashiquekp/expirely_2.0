
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/product_model.dart';
import '../../data/models/product_category.dart';
import '../providers/product_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1'); // e.g., "1"
  String _unit = 'items'; // items, kg, L, etc.
  ProductCategory _category = ProductCategory.other;
  
  DateTime _mfgDate = DateTime.now();
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  
  final _shelfLifeController = TextEditingController();
  String _shelfLifeUnit = 'Days';

  // Helper for date picker
  Future<void> _pickDate(bool isMfg) async {
    final initialDate = isMfg ? _mfgDate : _expiryDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isMfg) {
          _mfgDate = picked;
          _calculateExpiryFromShelfLife(_shelfLifeController.text);
        } else {
          _expiryDate = picked;
          // Optional: Reverse calculate shelf life? Maybe simpler to just let user override.
          _shelfLifeController.clear(); 
        }
      });
    }
  }

  void _calculateExpiryFromShelfLife(String value) {
    if (value.isEmpty) return;
    final duration = int.tryParse(value);
    if (duration == null) return;

    DateTime newExpiry = _mfgDate;
    if (_shelfLifeUnit == 'Days') {
      newExpiry = _mfgDate.add(Duration(days: duration));
    } else if (_shelfLifeUnit == 'Months') {
      // Approximate or precise? simple month addition
      newExpiry = DateTime(_mfgDate.year, _mfgDate.month + duration, _mfgDate.day);
    } else if (_shelfLifeUnit == 'Years') {
      newExpiry = DateTime(_mfgDate.year + duration, _mfgDate.month, _mfgDate.day);
    }
    
    setState(() {
      _expiryDate = newExpiry;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      
      final newProduct = ProductModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        category: _category,
        quantity: double.tryParse(_quantityController.text) ?? 1.0,
        unit: _unit,
        mfgDate: _mfgDate,
        expiryDate: _expiryDate,
      );
      
      try {
        await ref.read(productListProvider.notifier).addProduct(newProduct);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product Added!')));
          context.go('/products');
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
           setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _unit,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['items', 'kg', 'g', 'L', 'ml'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<ProductCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ProductCategory.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(c.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 24),
              
              _buildDateRow('Manufacturing Date', _mfgDate, () => _pickDate(true)),
              const SizedBox(height: 16),
              
              // Shelf Life Section
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _shelfLifeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Shelf Life',
                        border: OutlineInputBorder(),
                        //helperText: 'Auto-calculates expiry',
                      ),
                      onChanged: _calculateExpiryFromShelfLife,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _shelfLifeUnit,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['Days', 'Months', 'Years'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        setState(() => _shelfLifeUnit = v!);
                        _calculateExpiryFromShelfLife(_shelfLifeController.text);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildDateRow('Expiry Date', _expiryDate, () => _pickDate(false), color: Colors.blue.withValues(alpha: 0.1)),
              
              const SizedBox(height: 32),
              
              _isSaving 
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save),
                label: const Text('Save Product'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDateRow(String label, DateTime date, VoidCallback onTap, {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd().format(date), 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }
}
