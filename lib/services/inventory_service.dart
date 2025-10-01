import 'package:hive/hive.dart';
import '../models/inventory_item.dart';
import 'hive_service.dart';

class InventoryService {
  final String storeId;
  InventoryService(this.storeId);

  Future<Box> _box() => HiveService.openStoreBox(HiveService.boxInventoryPrefix, storeId);

  Future<List<InventoryItem>> all() async {
    final box = await _box();
    return box.values.cast<InventoryItem>().toList();
  }

  Future<List<InventoryItem>> search(String query) async {
    final box = await _box();
    final all = box.values.cast<InventoryItem>();
    final q = query.trim().toLowerCase();
    return all.where((i) => i.name.toLowerCase().contains(q) || i.sku.toLowerCase().contains(q)).toList();
  }

  Future<void> upsert(InventoryItem item) async {
    final box = await _box();
    await box.put(item.id, item..updatedAtMs = DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> delete(int id) async {
    final box = await _box();
    await box.delete(id);
  }

  Future<void> applyMovement({required int itemId, required int delta}) async {
    final box = await _box();
    final item = box.get(itemId) as InventoryItem?;
    if (item == null) return;
    item.quantity = (item.quantity + delta).clamp(0, 1 << 31);
    item.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    await item.save();
  }

  Future<List<InventoryItem>> lowStock() async {
    final box = await _box();
    return box.values.cast<InventoryItem>().where((i) => i.quantity <= i.lowStockThreshold).toList();
  }
}


