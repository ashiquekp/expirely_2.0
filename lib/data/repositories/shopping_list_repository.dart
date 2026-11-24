import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/hive_constants.dart';
import '../models/shopping_item_model.dart';

class ShoppingListRepository {
  static const _itemsKey = 'items';

  late Box<String> _shoppingListBox;

  Future<void> init() async {
    _shoppingListBox = await Hive.openBox<String>(
      HiveConstants.shoppingListBoxName,
    );
  }

  List<ShoppingItemModel> getAllItems() {
    final storedItems = _shoppingListBox.get(_itemsKey);
    if (storedItems == null) return [];

    final decodedItems = jsonDecode(storedItems) as List<dynamic>;
    return decodedItems
        .map(
          (item) => ShoppingItemModel.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<void> saveItems(List<ShoppingItemModel> items) async {
    final encodedItems = jsonEncode(
      items.map((item) => item.toJson()).toList(),
    );
    await _shoppingListBox.put(_itemsKey, encodedItems);
  }
}

final shoppingListRepositoryProvider = Provider<ShoppingListRepository>((ref) {
  return ShoppingListRepository();
});
