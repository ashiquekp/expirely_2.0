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

  factory ShoppingItemModel.fromJson(Map<String, dynamic> json) {
    return ShoppingItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      isCompleted: json['isCompleted'] as bool,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      category: ProductCategory.values.byName(json['category'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isCompleted': isCompleted,
      'quantity': quantity,
      'unit': unit,
      'category': category.name,
    };
  }

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
