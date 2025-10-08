import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:sqflite/sqflite.dart';
import '../services/local_db.dart';
import '../services/api_client.dart';
import '../services/retry_service.dart';

class UsersRepository {
  /// Carrega usuários do backend
  Future<List<Map<String, dynamic>>> getRemoteUsers() async {
    try {
      final response = await RetryService.networkRetry(
        () => ApiClient.get('/users', auth: true),
        operationName: 'buscar_usuarios_backend',
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
      
      return rawList.cast<Map<String, dynamic>>();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao buscar usuários do backend: $e');
      }
      rethrow;
    }
  }
  
  /// Sincroniza usuários do backend para o banco local
  Future<void> syncFromRemote() async {
    if (kIsWeb) return;
    
    try {
      final remoteUsers = await getRemoteUsers();
      final db = await LocalDb.instance();
      
      await RetryService.databaseRetry(
        () async {
          final batch = db.batch();
          
          for (final user in remoteUsers) {
            batch.insert(
              'users_local',
              {
                'id': user['id'],
                'name': user['name'],
                'email': user['email'],
                'role': user['role'],
                'status': user['status'],
                'store_id': user['storeId'] ?? user['store_id'],
                'store_name': user['storeName'] ?? user['store_name'],
                'blocked_until': user['blockedUntil'] ?? user['blocked_until'],
                'created_at': user['created_at'],
                'synced': 1,
                'updated_at': DateTime.now().millisecondsSinceEpoch,
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
          
          await batch.commit(noResult: true);
        },
        operationName: 'sincronizar_usuarios_locais',
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao sincronizar usuários do backend: $e');
      }
      // Não relançar o erro - usar dados locais como fallback
    }
  }
  
  /// Carrega usuários do banco local
  Future<List<Map<String, dynamic>>> getLocalUsers() async {
    if (kIsWeb) return [];
    
    final db = await LocalDb.instance();
    final rows = await db.query(
      'users_local',
      orderBy: 'created_at DESC',
    );
    
    return rows.map((row) => {
      'id': row['id'],
      'name': row['name'],
      'email': row['email'],
      'role': row['role'],
      'status': row['status'],
      'storeId': row['store_id'],
      'storeName': row['store_name'],
      'blockedUntil': row['blocked_until'],
      'created_at': row['created_at'],
    }).toList();
  }
  
  /// Cria usuário no backend
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await RetryService.networkRetry(
        () => ApiClient.post('/users', userData, auth: true),
        operationName: 'criar_usuario_backend',
      );
      
      if (response.statusCode != 201) {
        throw Exception('Falha na API: ${response.statusCode}');
      }
      
      final createdUser = jsonDecode(response.body) as Map<String, dynamic>;
      
      // Salvar localmente após criação bem-sucedida
      await _saveUserLocally(createdUser);
      
      return createdUser;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erro ao criar usuário: $e');
      }
      rethrow;
    }
  }
  
  /// Salva usuário localmente
  Future<void> _saveUserLocally(Map<String, dynamic> user) async {
    if (kIsWeb) return;
    
    final db = await LocalDb.instance();
    
    await RetryService.databaseRetry(
      () async {
        await db.insert('users_local', {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'role': user['role'],
          'status': user['status'],
          'store_id': user['storeId'] ?? user['store_id'],
          'store_name': user['storeName'] ?? user['store_name'],
          'blocked_until': user['blockedUntil'] ?? user['blocked_until'],
          'created_at': user['created_at'],
          'synced': 1,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      },
      operationName: 'salvar_usuario_local',
    );
  }
}
