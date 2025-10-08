import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:sqflite/sqflite.dart';
import '../services/local_db.dart';
import '../services/api_client.dart';
import '../services/retry_service.dart';
import '../models/client.dart';

class ClientsRepository {
  /// Salva cliente localmente
  Future<void> saveClientLocally(Client client) async {
    if (kIsWeb) return;
    
    final db = await LocalDb.instance();
    
    await RetryService.databaseRetry(
      () async {
        await db.insert('clients_local', {
          'id': client.id,
          'name': client.name,
          'phone': client.phone,
          'email': client.email,
          'address': client.address,
          'synced': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      },
      operationName: 'salvar_cliente_local',
    );
  }
  
  /// Adiciona cliente à fila de sincronização
  Future<void> queueClientForSync(Client client) async {
    if (kIsWeb) return;
    
    final db = await LocalDb.instance();
    
    await RetryService.databaseRetry(
      () async {
        await db.insert('clients_queue', {
          'client_data': jsonEncode({
            'name': client.name,
            'phone': client.phone,
            'email': client.email,
            'address': client.address,
          }),
          'retry_count': 0,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      },
      operationName: 'adicionar_cliente_fila',
    );
  }
  
  /// Sincroniza clientes pendentes com o backend
  Future<void> syncPendingClients() async {
    if (kIsWeb) return;
    
    final db = await LocalDb.instance();
    final pendingClients = await db.query(
      'clients_queue',
      where: 'retry_count < ?',
      whereArgs: [3],
      orderBy: 'created_at ASC',
    );
    
    for (final clientData in pendingClients) {
      try {
        final clientJson = jsonDecode(clientData['client_data'] as String);
        
        await RetryService.networkRetry(
          () async {
            final response = await ApiClient.post('/clients', clientJson, auth: true);
            if (response.statusCode != 201) {
              throw Exception('Falha na API: ${response.statusCode}');
            }
          },
          operationName: 'sincronizar_cliente_${clientData['id']}',
        );
        
        // Se chegou aqui, a sincronização foi bem-sucedida
        await db.delete('clients_queue', where: 'id = ?', whereArgs: [clientData['id']]);
        
        // Marcar como sincronizado na tabela local
        await db.update(
          'clients_local',
          {'synced': 1},
          where: 'name = ? AND phone = ?',
          whereArgs: [clientJson['name'], clientJson['phone']],
        );
        
      } catch (e) {
        // Incrementar contador de tentativas
        await db.update(
          'clients_queue',
          {'retry_count': (clientData['retry_count'] as int) + 1},
          where: 'id = ?',
          whereArgs: [clientData['id']],
        );
        
        if (kDebugMode) {
          print('❌ Falha ao sincronizar cliente ${clientData['id']}: $e');
        }
      }
    }
  }
  
  /// Carrega clientes do banco local
  Future<List<Client>> getLocalClients() async {
    if (kIsWeb) return [];
    
    final db = await LocalDb.instance();
    final rows = await db.query(
      'clients_local',
      orderBy: 'created_at DESC',
    );
    
    return rows.map((row) => Client(
      id: row['id'] as int?,
      name: row['name'] as String,
      phone: row['phone'] as String,
      email: row['email'] as String?,
      address: row['address'] as String?,
    )).toList();
  }
  
  /// Carrega clientes do backend
  Future<List<Client>> getRemoteClients() async {
    try {
      final response = await RetryService.networkRetry(
        () => ApiClient.get('/clients', auth: true),
        operationName: 'buscar_clientes_backend',
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
          : <dynamic>[];
      
      return rawList.map((m) => Client(
        id: m['id'],
        name: m['name'],
        phone: m['phone'],
        email: m['email'],
        address: m['address'],
      )).toList();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar clientes do backend: $e');
      }
      rethrow;
    }
  }
  
  /// Sincroniza clientes do backend para o banco local
  Future<void> syncFromRemote() async {
    if (kIsWeb) return;
    
    try {
      final remoteClients = await getRemoteClients();
      final db = await LocalDb.instance();
      
      await RetryService.databaseRetry(
        () async {
          final batch = db.batch();
          
          for (final client in remoteClients) {
            batch.insert(
              'clients_local',
              {
                'id': client.id,
                'name': client.name,
                'phone': client.phone,
                'email': client.email,
                'address': client.address,
                'synced': 1,
                'created_at': DateTime.now().millisecondsSinceEpoch,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          
          await batch.commit(noResult: true);
        },
        operationName: 'sincronizar_clientes_locais',
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao sincronizar clientes do backend: $e');
      }
      // Não relançar o erro - usar dados locais como fallback
    }
  }
}
