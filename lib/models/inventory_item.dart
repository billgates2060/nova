import 'package:hive/hive.dart';

part 'inventory_item.g.dart';

@HiveType(typeId: 3)
class InventoryItem extends HiveObject {
  @HiveField(0)
  int id;

  @HiveField(1)
  String storeId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String sku;

  @HiveField(4)
  double cost;

  @HiveField(5)
  double price;

  @HiveField(6)
  int quantity;

  @HiveField(7)
  int lowStockThreshold;

  @HiveField(8)
  int updatedAtMs;

  InventoryItem({
    required this.id,
    required this.storeId,
    required this.name,
    required this.sku,
    required this.cost,
    required this.price,
    required this.quantity,
    required this.lowStockThreshold,
    required this.updatedAtMs,
  });
}


