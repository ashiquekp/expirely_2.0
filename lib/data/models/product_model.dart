
import 'package:hive/hive.dart';
import 'product_category.dart';

part 'product_model.g.dart';

@HiveType(typeId: 0)
class ProductModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final ProductCategory category;

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final String unit; // e.g., 'items', 'kg', 'L'

  @HiveField(5)
  final DateTime mfgDate;

  @HiveField(6)
  final DateTime expiryDate;

  @HiveField(7)
  final bool isConsumed;

  @HiveField(8)
  final String? imagePath; // Optional path to local image

  @HiveField(9)
  final DateTime? notificationId; // To cancel schedule if needed, or use ID hash

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.mfgDate,
    required this.expiryDate,
    this.isConsumed = false,
    this.imagePath,
    this.notificationId,
  });
  
  // Helper to get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiration.difference(today).inDays;
  }
}
