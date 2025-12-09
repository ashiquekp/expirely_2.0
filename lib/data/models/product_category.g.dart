// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductCategoryAdapter extends TypeAdapter<ProductCategory> {
  @override
  final int typeId = 1;

  @override
  ProductCategory read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ProductCategory.food;
      case 1:
        return ProductCategory.medicine;
      case 2:
        return ProductCategory.cosmetics;
      case 3:
        return ProductCategory.other;
      default:
        return ProductCategory.food;
    }
  }

  @override
  void write(BinaryWriter writer, ProductCategory obj) {
    switch (obj) {
      case ProductCategory.food:
        writer.writeByte(0);
        break;
      case ProductCategory.medicine:
        writer.writeByte(1);
        break;
      case ProductCategory.cosmetics:
        writer.writeByte(2);
        break;
      case ProductCategory.other:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
