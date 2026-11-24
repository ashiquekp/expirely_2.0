import 'dart:io';

import 'package:expirely/data/models/product_category.dart';
import 'package:expirely/data/repositories/shopping_list_repository.dart';
import 'package:expirely/presentation/providers/shopping_list_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() {
  late Directory storageDirectory;
  late ShoppingListRepository repository;

  setUp(() async {
    storageDirectory = await Directory.systemTemp.createTemp(
      'expirely_shopping_list_test',
    );
    Hive.init(storageDirectory.path);
    repository = ShoppingListRepository();
    await repository.init();
  });

  tearDown(() async {
    await Hive.close();
    await storageDirectory.delete(recursive: true);
  });

  test('shopping list entries survive closing and reopening storage', () async {
    final firstContainer = ProviderContainer(
      overrides: [shoppingListRepositoryProvider.overrideWithValue(repository)],
    );
    await firstContainer
        .read(shoppingListProvider.notifier)
        .addItem(
          'Oats',
          quantity: 1.5,
          unit: 'kg',
          category: ProductCategory.food,
        );
    final savedItem = firstContainer.read(shoppingListProvider).single;
    firstContainer.dispose();

    await Hive.close();

    Hive.init(storageDirectory.path);
    repository = ShoppingListRepository();
    await repository.init();

    final secondContainer = ProviderContainer(
      overrides: [shoppingListRepositoryProvider.overrideWithValue(repository)],
    );
    final restoredItems = secondContainer.read(shoppingListProvider);
    expect(restoredItems, hasLength(1));
    expect(restoredItems.single.toJson(), savedItem.toJson());
    secondContainer.dispose();
  });
}
