
import 'package:flutter_test/flutter_test.dart';
import 'package:expirely/data/models/product_model.dart';
import 'package:expirely/data/models/product_category.dart';

void main() {
  group('ProductModel Tests', () {
    test('daysRemaining calculation is correct', () {
      final now = DateTime.now();
      final futureDate = now.add(const Duration(days: 5));
      
      final product = ProductModel(
        id: '1',
        name: 'Test',
        category: ProductCategory.food,
        quantity: 1,
        unit: 'item',
        mfgDate: now,
        expiryDate: futureDate,
      );

      // Depending on time of day, it might be 4 or 5. 
      // The logic uses DateTime(y,m,d) to strip time.
      // So if today is 10th, future is 15th. 15-10 = 5.
      expect(product.daysRemaining, 5);
    });

    test('daysRemaining for expired product', () {
      final now = DateTime.now();
      final pastDate = now.subtract(const Duration(days: 2));
      
      final product = ProductModel(
        id: '1',
        name: 'Test',
        category: ProductCategory.food,
        quantity: 1,
        unit: 'item',
        mfgDate: now.subtract(const Duration(days: 10)),
        expiryDate: pastDate,
      );

      expect(product.daysRemaining, -2);
    });
  });
}
