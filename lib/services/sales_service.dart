import 'package:hive/hive.dart';
import '../models/inventory_item.dart';
import 'hive_service.dart';

class CartItem {
  final int itemId;
  final String name;
  final double unitPrice;
  int quantity;
  CartItem({required this.itemId, required this.name, required this.unitPrice, required this.quantity});
}

class SalesService {
  final String storeId;
  SalesService(this.storeId);

  double total(List<CartItem> cart) => cart.fold(0.0, (s, c) => s + c.unitPrice * c.quantity);

  double applyDiscount(double total, {double? percent, double? fixed}) {
    if (percent != null) return (total * (1.0 - percent / 100)).clamp(0, double.infinity);
    if (fixed != null) return (total - fixed).clamp(0, double.infinity);
    return total;
  }

  double troco(double paid, double due) => (paid - due).clamp(0, double.infinity);

  Future<void> commitSale(List<CartItem> cart) async {
    final invBox = await HiveService.openStoreBox(HiveService.boxInventoryPrefix, storeId);
    for (final c in cart) {
      final item = invBox.get(c.itemId) as InventoryItem?;
      if (item == null) continue;
      item.quantity = (item.quantity - c.quantity).clamp(0, 1 << 31);
      item.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      await item.save();
    }
    // TODO: persist sale record in per-store sales box for reports
  }
}


