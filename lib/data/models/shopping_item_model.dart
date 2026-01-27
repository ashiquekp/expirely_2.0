import 'product_category.dart';

class ShoppingItemModel {
  final String id;
  final String name;
  final bool isCompleted;
  final double quantity;
  final String unit;
  final ProductCategory category;

  ShoppingItemModel({
    required this.id,
    required this.name,
    this.isCompleted = false,
    this.quantity = 1.0,
    this.unit = 'items',
    this.category = ProductCategory.other,
  });

  ShoppingItemModel copyWith({
    String? id,
    String? name,
    bool? isCompleted,
    double? quantity,
    String? unit,
    ProductCategory? category,
  }) {
    return ShoppingItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      isCompleted: isCompleted ?? this.isCompleted,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      category: category ?? this.category,
    );
  }
}
