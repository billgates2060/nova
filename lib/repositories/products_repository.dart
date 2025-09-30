import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../services/local_db.dart';
import '../services/api_client.dart';

class ProductsRepository {
  Future<List<Map<String, dynamic>>> getAllLocal() async {
    final db = await LocalDb.instance();
    return db.query('products', orderBy: 'updated_at DESC');
  }

  Future<void> upsertLocal(Map<String, dynamic> product) async {
    final db = await LocalDb.instance();
    await db.insert(
      'products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> queueOp(String op, Map<String, dynamic> payload) async {
    final db = await LocalDb.instance();
    await db.insert('ops_queue', {
      'entity': 'product',
      'op': op,
      'payload': jsonEncode(payload),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> syncFromRemote() async {
    final resp = await ApiClient.get('/products', auth: true);
    if (resp.statusCode == 200) {
      final list = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
      final db = await LocalDb.instance();
      final batch = db.batch();
      for (final p in list) {
        batch.insert('products', {
          'id': p['id'],
          'name': p['name'],
          'price': p['price'],
          'stock': p['stock'],
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> pushQueue() async {
    final db = await LocalDb.instance();
    final ops = await db.query(
      'ops_queue',
      where: 'entity = ?',
      whereArgs: ['product'],
      orderBy: 'created_at ASC',
    );
    for (final op in ops) {
      final payload =
          jsonDecode(op['payload'] as String) as Map<String, dynamic>;
      if (op['op'] == 'create') {
        await ApiClient.post('/products', payload, auth: true);
      } else if (op['op'] == 'update') {
        await ApiClient.put('/products/${payload['id']}', payload, auth: true);
      } else if (op['op'] == 'delete') {
        await ApiClient.delete('/products/${payload['id']}', auth: true);
      }
      await db.delete('ops_queue', where: 'id = ?', whereArgs: [op['id']]);
    }
  }
}
