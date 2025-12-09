
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit; // Not implementing Edit fully yet, but good to have

  const ProductCard({
    super.key,
    required this.product,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final days = product.daysRemaining;
    Color statusColor;
    String statusText;

    if (days < 0) {
      statusColor = Colors.red;
      statusText = 'Expired';
    } else if (days <= 7) {
      statusColor = Colors.orange;
      statusText = '$days days left';
    } else {
      statusColor = Colors.green;
      statusText = 'Fresh';
    }

    return Dismissible(
      key: Key(product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0, // Using outlined or filled variant style often looks cleaner
        color: Theme.of(context).colorScheme.surfaceContainerLow, 
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              PhosphorIconsRegular.package, // Could use category icon
              color: statusColor,
            ),
          ),
          title: Text(
            product.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${product.quantity} ${product.unit} • ${product.category.name.toUpperCase()}'),
              Text(
                'Expires: ${DateFormat.yMMMd().format(product.expiryDate)} ($statusText)',
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
        ),
      ),
    );
  }
}
