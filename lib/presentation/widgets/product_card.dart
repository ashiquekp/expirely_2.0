import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../data/models/product_model.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit; // Not implementing Edit fully yet, but good to have
  final VoidCallback? onRestock;

  const ProductCard({
    super.key,
    required this.product,
    this.onDelete,
    this.onEdit,
    this.onRestock,
  });

  @override
  Widget build(BuildContext context) {
    final days = product.daysRemaining;
    Color statusColor;
    //String statusText;

    if (days < 0) {
      statusColor = Colors.red;
     // statusText = 'Expired';
    } else if (days <= 7) {
      statusColor = Colors.orange;
      //statusText = '$days days left';
    } else {
      statusColor = Colors.green;
      //statusText = 'Fresh';
    }

    String displayedQuantity = product.quantity % 1 == 0
        ? product.quantity.toInt().toString()
        : product.quantity.toString();
    String displayedUnit = product.unit;
    if (displayedUnit.toLowerCase() == 'items' && product.quantity == 1) {
      displayedUnit = 'item';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation:
          0, // Using outlined or filled variant style often looks cleaner
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
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
            Text(
              '$displayedQuantity $displayedUnit • ${product.category.name.toUpperCase()}',
            ),
            Text(
              'Expires: ${DateFormat.yMMMd().format(product.expiryDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
              ),
              child: Text(
                days < 0
                    ? 'EXPIRED'
                    : (days == 1 ? '$days DAY LEFT' :  days > 1 && days <= 7 ? '$days DAYS LEFT' : 'FRESH'),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (days < 0)
              IconButton(
                icon: const Icon(PhosphorIconsRegular.shoppingCart),
                tooltip: 'Add to Shopping List',
                onPressed: onRestock,
                color: Theme.of(context).colorScheme.primary,
              ),
            IconButton(
              icon: const Icon(
                Icons.delete_forever,
                size: 24,
                color: Colors.grey,
              ), // Grey to not distract from status
              onPressed: onDelete,
              tooltip: 'Delete Product',
            ),
          ],
        ),
      ),
    );
  }
}
