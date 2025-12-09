
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/hive_constants.dart';
import '../models/product_model.dart';

class ProductRepository {
  late Box<ProductModel> _productBox;

  Future<void> init() async {
    _productBox = await Hive.openBox<ProductModel>(HiveConstants.productBoxName);
  }

  List<ProductModel> getAllProducts() {
    if (!_productBox.isOpen) return [];
    return _productBox.values.toList();
  }

  Future<void> addProduct(ProductModel product) async {
    await _productBox.put(product.id, product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await _productBox.put(product.id, product);
  }

  Future<void> deleteProduct(String id) async {
    await _productBox.delete(id);
  }

  Future<void> deleteAllProducts() async {
    await _productBox.clear();
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});
