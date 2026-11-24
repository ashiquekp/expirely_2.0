import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/shopping_item_model.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/product_category.dart';
import '../../data/repositories/shopping_list_repository.dart';

class ShoppingListNotifier extends Notifier<List<ShoppingItemModel>> {
  late ShoppingListRepository _repo;

  @override
  List<ShoppingItemModel> build() {
    _repo = ref.read(shoppingListRepositoryProvider);
    return _repo.getAllItems();
  }

  Future<void> addItem(
    String name, {
    double quantity = 1.0,
    String unit = 'items',
    ProductCategory category = ProductCategory.other,
  }) async {
    if (name.trim().isEmpty) return;
    final newItem = ShoppingItemModel(
      id: const Uuid().v4(),
      name: name.trim(),
      quantity: quantity,
      unit: unit,
      category: category,
    );
    await _saveItems([...state, newItem]);
  }

  Future<void> toggleComplete(String id) async {
    await _saveItems([
      for (final item in state)
        if (item.id == id)
          item.copyWith(isCompleted: !item.isCompleted)
        else
          item,
    ]);
  }

  Future<void> deleteItem(String id) async {
    await _saveItems(state.where((item) => item.id != id).toList());
  }

  Future<void> deleteCompleted() async {
    await _saveItems(state.where((item) => !item.isCompleted).toList());
  }

  Future<void> _saveItems(List<ShoppingItemModel> items) async {
    await _repo.saveItems(items);
    state = items;
  }
}

final shoppingListProvider =
    NotifierProvider<ShoppingListNotifier, List<ShoppingItemModel>>(
      ShoppingListNotifier.new,
    );
