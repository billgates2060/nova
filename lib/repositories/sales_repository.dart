import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:sqflite/sqflite.dart';
import '../services/local_db.dart';
import '../services/api_client.dart';
import '../services/retry_service.dart';
import '../models/sale.dart';

class SalesRepository {
  /// Salva venda localmente e na fila de sincronização
  Future<void> saveSaleLocally(Sale sale) async {
    if (kIsWeb) return; // Web não usa banco local
    
    final db = await LocalDb.instance();
    
    await RetryService.databaseRetry(
      () async {
        await db.insert('sales_local', {
          'product_id': sale.productId,
          'product_name': sale.productName,
          'quantity': sale.quantity,
          'unit_price': sale.unitPrice,
          'total_price': sale.totalPrice,
          'sale_date': sale.saleDate.toIso8601String(),
          'client_id': sale.clientId,
          'client_name': sale.clientName,
          'synced': 0, // Não sincronizado ainda
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      },
      operationName: 'salvar_venda_local',
    );
  }
  
  /// Adiciona venda à fila de sincronização
  Future<void> queueSaleForSync(Sale sale) async {
    if (kIsWeb) return;
    
    final db = await LocalDb.instance();
    
    await RetryService.databaseRetry(
      () async {
        await db.insert('sales_queue', {
          'sale_data': jsonEncode({
            'product_id': sale.productId,
            'product_name': sale.productName,
            'quantity': sale.quantity,
            'unit_price': sale.unitPrice,
            'total_price': sale.totalPrice,
            'sale_date': sale.saleDate.toIso8601String(),
            'client_id': sale.clientId,
          }),
          'retry_count': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      },
      operationName: 'adicionar_venda_fila',
    );
  }
  
  /// Sincroniza vendas pendentes com o backend
  Future<void> syncPendingSales() async {
    if (kIsWeb) return;
    
    final db = await LocalDb.instance();
    final pendingSales = await db.query(
      'sales_queue',
      where: 'retry_count < ?',
      whereArgs: [3], // Máximo 3 tentativas
      orderBy: 'created_at ASC',
    );
    
    for (final saleData in pendingSales) {
      try {
        final saleJson = jsonDecode(saleData['sale_data'] as String);
        
        await RetryService.networkRetry(
          () async {
            final response = await ApiClient.post('/sales', saleJson, auth: true);
            if (response.statusCode != 201) {
              throw Exception('Falha na API: ${response.statusCode}');
            }
          },
          operationName: 'sincronizar_venda_${saleData['id']}',
        );
        
        // Se chegou aqui, a sincronização foi bem-sucedida
        await db.delete('sales_queue', where: 'id = ?', whereArgs: [saleData['id']]);
        
        // Marcar como sincronizado na tabela local
        await db.update(
          'sales_local',
          {'synced': 1},
          where: 'product_id = ? AND sale_date = ?',
          whereArgs: [saleJson['product_id'], saleJson['sale_date']],
        );
        
        // Atualizar estoque local após sincronização bem-sucedida
        await _updateLocalStock(saleJson);
        
      } catch (e) {
        // Incrementar contador de tentativas
        await db.update(
          'sales_queue',
          {'retry_count': (saleData['retry_count'] as int) + 1},
          where: 'id = ?',
          whereArgs: [saleData['id']],
        );
        
        if (kDebugMode) {
          print('❌ Falha ao sincronizar venda ${saleData['id']}: $e');
        }
      }
    }
  }
  
  /// Atualiza estoque local após venda
  Future<void> _updateLocalStock(Map<String, dynamic> saleJson) async {
    try {
      final db = await LocalDb.instance();
      final productId = saleJson['product_id'] as int;
      final quantity = saleJson['quantity'] as int;
      
      // Buscar produto atual
      final product = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [productId],
      );
      
      if (product.isNotEmpty) {
        final currentStock = product.first['stock'] as int;
        final newStock = (currentStock - quantity).clamp(0, 1 << 31);
        
        // Atualizar estoque
        await db.update(
          'products',
          {
            'stock': newStock,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [productId],
        );
        
        if (kDebugMode) {
          print('✅ Estoque atualizado: Produto $productId, estoque: $currentStock -> $newStock');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao atualizar estoque local: $e');
      }
    }
  }
  
  /// Carrega vendas do banco local
  Future<List<Sale>> getLocalSales() async {
    if (kIsWeb) return [];
    
    final db = await LocalDb.instance();
    final rows = await db.query(
      'sales_local',
      orderBy: 'created_at DESC',
    );
    
    return rows.map((row) => Sale(
      id: row['id'] as int?,
      productId: row['product_id'] as int,
      productName: row['product_name'] as String,
      quantity: row['quantity'] as int,
      unitPrice: (row['unit_price'] as num).toDouble(),
      totalPrice: (row['total_price'] as num).toDouble(),
      saleDate: DateTime.parse(row['sale_date'] as String),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      clientId: row['client_id'] as int?,
      clientName: row['client_name'] as String?,
    )).toList();
  }
  
  /// Carrega vendas do backend
  Future<List<Sale>> getRemoteSales() async {
    try {
      final response = await RetryService.networkRetry(
        () => ApiClient.get('/sales', auth: true),
        operationName: 'buscar_vendas_backend',
      );
      
      if (response.statusCode != 200) {
        throw Exception('Falha na API: ${response.statusCode}');
      }
      
      final decoded = jsonDecode(response.body);
      final List<dynamic> rawList = decoded is List
          ? decoded
          : (decoded is Map && decoded['items'] is List)
          ? decoded['items'] as List
          : (decoded is Map && decoded['data'] is List)
          ? decoded['data'] as List
          : (decoded is Map && decoded['sales'] is List)
          ? decoded['sales'] as List
          : <dynamic>[];
      
      return rawList.map((m) => Sale(
        id: m['id'],
        productId: m['product_id'],
        productName: m['product_name'],
        quantity: (m['quantity'] as num).toInt(),
        unitPrice: (m['unit_price'] as num).toDouble(),
        totalPrice: (m['total_price'] as num).toDouble(),
        saleDate: DateTime.parse(m['sale_date']),
        createdAt: DateTime.parse(m['created_at']),
        clientId: m['client_id'] as int?,
        clientName: m['client_name'] as String?,
      )).toList();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar vendas do backend: $e');
      }
      rethrow;
    }
  }
  
  /// Sincroniza vendas do backend para o banco local
  Future<void> syncFromRemote() async {
    if (kIsWeb) return;
    
    try {
      final remoteSales = await getRemoteSales();
      final db = await LocalDb.instance();
      
      await RetryService.databaseRetry(
        () async {
          final batch = db.batch();
          
          for (final sale in remoteSales) {
            batch.insert(
              'sales_local',
              {
                'id': sale.id,
                'product_id': sale.productId,
                'product_name': sale.productName,
                'quantity': sale.quantity,
                'unit_price': sale.unitPrice,
                'total_price': sale.totalPrice,
                'sale_date': sale.saleDate.toIso8601String(),
                'client_id': sale.clientId,
                'client_name': sale.clientName,
                'synced': 1, // Já sincronizado
                'created_at': sale.createdAt.millisecondsSinceEpoch,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          
          await batch.commit(noResult: true);
        },
        operationName: 'sincronizar_vendas_locais',
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao sincronizar vendas do backend: $e');
      }
      // Não relançar o erro - usar dados locais como fallback
    }
  }
  
  /// Obtém estatísticas de sincronização
  Future<Map<String, int>> getSyncStats() async {
    if (kIsWeb) return {'total': 0, 'synced': 0, 'pending': 0, 'failed': 0};
    
    final db = await LocalDb.instance();
    
    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM sales_local');
    final syncedResult = await db.rawQuery('SELECT COUNT(*) as count FROM sales_local WHERE synced = 1');
    final pendingResult = await db.rawQuery('SELECT COUNT(*) as count FROM sales_queue WHERE retry_count < 3');
    final failedResult = await db.rawQuery('SELECT COUNT(*) as count FROM sales_queue WHERE retry_count >= 3');
    
    return {
      'total': totalResult.first['count'] as int,
      'synced': syncedResult.first['count'] as int,
      'pending': pendingResult.first['count'] as int,
      'failed': failedResult.first['count'] as int,
    };
  }
}
