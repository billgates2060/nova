import 'package:hive/hive.dart';
import '../models/client.dart';
import 'hive_service.dart';

class ClientsService {
  final String storeId;
  ClientsService(this.storeId);

  Future<Box> _box() => HiveService.openStoreBox(HiveService.boxClientsPrefix, storeId);

  Future<void> upsert(Client c) async => (await _box()).put(c.id, c);
  Future<void> delete(int id) async => (await _box()).delete(id);

  Future<List<Client>> search(String q) async {
    final all = (await _box()).values.cast<Client>();
    final s = q.trim().toLowerCase();
    return all.where((c) => c.name.toLowerCase().contains(s) || c.phone.contains(q)).toList();
  }
}


