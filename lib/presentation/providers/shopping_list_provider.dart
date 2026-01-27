
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/shopping_item_model.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/product_category.dart';

class ShoppingListNotifier extends Notifier<List<ShoppingItemModel>> {
  @override
  List<ShoppingItemModel> build() {
    // Initial dummy data for testing UI (can be removed later)
    return [
      ShoppingItemModel(id: const Uuid().v4(), name: 'Milk', quantity: 2, unit: 'L', category: ProductCategory.food),
      ShoppingItemModel(id: const Uuid().v4(), name: 'Tylenol', isCompleted: true, category: ProductCategory.medicine),
      ShoppingItemModel(id: const Uuid().v4(), name: 'Eggs', quantity: 12, unit: 'items', category: ProductCategory.food),
    ];
  }

  void addItem(String name, {double quantity = 1.0, String unit = 'items', ProductCategory category = ProductCategory.other}) {
    if (name.trim().isEmpty) return;
    final newItem = ShoppingItemModel(
      id: const Uuid().v4(),
      name: name.trim(),
      quantity: quantity,
      unit: unit,
      category: category,
    );
    state = [...state, newItem];
  }

  void toggleComplete(String id) {
    state = [
      for (final item in state)
        if (item.id == id)
          item.copyWith(isCompleted: !item.isCompleted)
        else
          item,
    ];
  }

  void deleteItem(String id) {
    state = state.where((item) => item.id != id).toList();
  }
  
  void deleteCompleted() {
    state = state.where((item) => !item.isCompleted).toList();
  }
}

final shoppingListProvider = NotifierProvider<ShoppingListNotifier, List<ShoppingItemModel>>(ShoppingListNotifier.new);
