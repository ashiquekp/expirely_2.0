import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../providers/product_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/product_card.dart';
import '../../data/models/product_model.dart'; // Needed for type

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String _searchQuery = '';
  String _filter = 'All'; // All, Expired, Expiring Soon, Fresh
  String _sort = 'Date'; // Date, Name

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productListProvider);

    // Filter Logic
    List<ProductModel> filtered = products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      if (!matchesSearch) return false;

      if (_filter == 'Expired') return p.daysRemaining < 0;
      if (_filter == 'Expiring Soon')
        return p.daysRemaining >= 0 && p.daysRemaining <= 7;
      if (_filter == 'Fresh') return p.daysRemaining > 7;

      return true; // matching 'All'
    }).toList();

    // Sort Logic
    if (_sort == 'Name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else {
      // Date
      filtered.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(PhosphorIconsRegular.trash),
            tooltip: 'Clear Expired',
            onPressed: () {
              // Confirm dialog
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Expired?'),
                  content: const Text('This will remove all expired items.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(productListProvider.notifier).deleteExpired();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(PhosphorIconsRegular.sortAscending),
            onSelected: (val) => setState(() => _sort = val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Date', child: Text('Sort by Date')),
              const PopupMenuItem(value: 'Name', child: Text('Sort by Name')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(
                      PhosphorIconsRegular.magnifyingGlass,
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilter('All'),
                      const SizedBox(width: 8),
                      _buildFilter('Expiring Soon'),
                      const SizedBox(width: 8),
                      _buildFilter('Fresh'),
                      const SizedBox(width: 8),
                      _buildFilter('Expired'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No products found.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ProductCard(
                        product: product,
                        onRestock: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Restock Product?'),
                              content: Text(
                                'Do you want to add "${product.name}" to your shopping list?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(shoppingListProvider.notifier)
                                          .addItem(
                                            product.name,
                                            quantity: product.quantity,
                                            unit: product.unit,
                                            category: product.category,
                                          );
                                      await ref
                                          .read(productListProvider.notifier)
                                          .deleteProduct(product.id);
                                      if (!context.mounted) return;
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${product.name} added to shopping list',
                                          ),
                                        ),
                                      );
                                    } catch (error) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Could not add to shopping list: $error',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Add to List'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDelete: () {
                          debugPrint('Delete clicked for ${product.name}');
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Product?'),
                              content: Text(
                                'Are you sure you want to delete "${product.name}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(productListProvider.notifier)
                                        .deleteProduct(product.id);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${product.name} deleted',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilter(String label) {
    final isSelected = _filter == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) => setState(() => _filter = val ? label : 'All'),
    );
  }
}
