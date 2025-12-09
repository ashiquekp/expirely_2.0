
import 'package:hive/hive.dart';

part 'product_category.g.dart';

@HiveType(typeId: 1)
enum ProductCategory {
  @HiveField(0)
  food,
  @HiveField(1)
  medicine,
  @HiveField(2)
  cosmetics,
  @HiveField(3)
  other,
}
