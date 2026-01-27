
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/product_category.dart';
import '../../data/models/product_model.dart';
import '../../data/models/shopping_item_model.dart';
import '../providers/product_provider.dart';
import '../providers/shopping_list_provider.dart';

class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  String _unit = 'items';
  ProductCategory _category = ProductCategory.other;

  void _showAddItemModal() {
    // Reset defaults
    _itemController.clear();
    _quantityController.text = '1';
    _unit = 'items';
    _category = ProductCategory.other;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            // ... existing modal code ...
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Add Item',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _itemController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'What do you need to buy?',
                      labelText: 'Item Name',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(PhosphorIconsRegular.shoppingCart),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          value: _unit,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          items: ['items', 'kg', 'g', 'L', 'ml', 'pcs'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setModalState(() => _unit = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ProductCategory>(
                    value: _category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(PhosphorIconsRegular.tag),
                    ),
                    items: ProductCategory.values.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (v) => setModalState(() => _category = v!),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(PhosphorIconsBold.plus),
                    label: const Text('Add to List'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  void _addItem() {
    if (_itemController.text.trim().isNotEmpty) {
      ref.read(shoppingListProvider.notifier).addItem(
        _itemController.text,
        quantity: double.tryParse(_quantityController.text) ?? 1.0,
        unit: _unit,
        category: _category,
      );
      Navigator.pop(context);
    }
  }

  Future<void> _startMoveToInventory(ShoppingItemModel item) async {
    final DateTime? pickedDate = await showDialog<DateTime>(
      context: context,
      builder: (context) => MoveToInventoryDialog(itemName: item.name),
    );

    if (pickedDate != null) {
      final now = DateTime.now();
      // Add to main inventory
      final newProduct = ProductModel(
        id: const Uuid().v4(),
        name: item.name,
        category: item.category,
        quantity: item.quantity,
        unit: item.unit,
        mfgDate: now, // Assume bought today
        expiryDate: pickedDate,
      );

      await ref.read(productListProvider.notifier).addProduct(newProduct);
      
      // Remove from shopping list
      ref.read(shoppingListProvider.notifier).deleteItem(item.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Moved ${item.name} to inventory')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shoppingList = ref.watch(shoppingListProvider);
    final completedCount = shoppingList.where((i) => i.isCompleted).length;
    final totalCount = shoppingList.length;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          if (completedCount > 0)
            IconButton(
              icon: const Icon(PhosphorIconsRegular.trashSimple),
              tooltip: 'Clear Completed',
              onPressed: () {
                 ref.read(shoppingListProvider.notifier).deleteCompleted();
              },
            )
        ],
      ),
      body: Column(
        children: [
          // Header Card
          if (shoppingList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                      strokeWidth: 8,
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedCount / $totalCount bought',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          overallStatus(progress),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // List
          Expanded(
            child: shoppingList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsRegular.shoppingBagOpen, size: 64, color: Theme.of(context).disabledColor),
                        const SizedBox(height: 16),
                        Text(
                          'Your list is empty',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).disabledColor,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: shoppingList.length,
                    itemBuilder: (context, index) {
                      final item = shoppingList[index];
                      return Dismissible(
                        key: ValueKey(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          ref.read(shoppingListProvider.notifier).deleteItem(item.id);
                        },
                        child: Card(
                          elevation: 0,
                          color: item.isCompleted
                              ? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5)
                              : Theme.of(context).cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor.withOpacity(0.1),
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              ref.read(shoppingListProvider.notifier).toggleComplete(item.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: item.isCompleted
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).disabledColor,
                                        width: 2,
                                      ),
                                      color: item.isCompleted
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                    ),
                                    padding: const EdgeInsets.all(2),
                                    child: item.isCompleted
                                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                                        : const SizedBox(width: 16, height: 16),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.name,
                                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                                                color: item.isCompleted ? Theme.of(context).disabledColor : null,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                        if (!item.isCompleted)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primaryContainer,
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Text(
                                                    '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.unit}',
                                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  item.category.name.toUpperCase(),
                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: Theme.of(context).disabledColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (item.isCompleted)
                                    IconButton(
                                      onPressed: () => _startMoveToInventory(item), 
                                      icon: const Icon(Icons.archive),
                                      // icon: const Icon(PhosphorIconsRegular.archiveBox),
                                      tooltip: 'Move to Inventory',
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemModal,
        child: const Icon(PhosphorIconsBold.plus),
      ),
    );
  }

  String overallStatus(double progress) {
    if (progress == 0) return 'Let\'s go shopping!';
    if (progress == 1) return 'All done! 🎉';
    if (progress > 0.5) return 'Almost there!';
    return 'Keep going!';
  }
}

class MoveToInventoryDialog extends StatefulWidget {
  final String itemName;
  const MoveToInventoryDialog({super.key, required this.itemName});

  @override
  State<MoveToInventoryDialog> createState() => _MoveToInventoryDialogState();
}

class _MoveToInventoryDialogState extends State<MoveToInventoryDialog> {
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  final _shelfLifeController = TextEditingController();
  String _shelfLifeUnit = 'Days';

  void _calculateExpiryFromShelfLife(String value) {
    if (value.isEmpty) return;
    final duration = int.tryParse(value);
    if (duration == null) return;
    final today = DateTime.now();

    DateTime newExpiry = today;
    if (_shelfLifeUnit == 'Days') {
      newExpiry = today.add(Duration(days: duration));
    } else if (_shelfLifeUnit == 'Months') {
      newExpiry = DateTime(today.year, today.month + duration, today.day);
    } else if (_shelfLifeUnit == 'Years') {
      newExpiry = DateTime(today.year + duration, today.month, today.day);
    }
    
    setState(() {
      _expiryDate = newExpiry;
    });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: now,
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
        _shelfLifeController.clear(); // Clear manual shelf life if specific date picked
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Move "${widget.itemName}"'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calculated Expiry Date:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat.yMMMd().format(_expiryDate)),
                    const Icon(Icons.edit_calendar, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Or Enter Shelf Life:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
             Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _shelfLifeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      onChanged: _calculateExpiryFromShelfLife,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _shelfLifeUnit,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: ['Days', 'Months', 'Years'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) {
                        setState(() => _shelfLifeUnit = v!);
                        _calculateExpiryFromShelfLife(_shelfLifeController.text);
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, _expiryDate),
          child: const Text('Move'),
        ),
      ],
    );
  }
}
