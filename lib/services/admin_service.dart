import 'dart:convert';
import 'api_client.dart';

class StoreInfo {
  final String storeId;
  final String storeName;

  StoreInfo({
    required this.storeId,
    required this.storeName,
  });

  factory StoreInfo.fromJson(Map<String, dynamic> json) {
    return StoreInfo(
      storeId: json['store_id'],
      storeName: json['store_name'],
    );
  }
}

class StoreStats {
  final int users;
  final int activeUsers;
  final int salesCount;
  final double revenue;
  final int productsCount;
  final int clientsCount;

  StoreStats({
    required this.users,
    required this.activeUsers,
    required this.salesCount,
    required this.revenue,
    required this.productsCount,
    required this.clientsCount,
  });

  factory StoreStats.fromJson(Map<String, dynamic> json) {
    return StoreStats(
      users: json['users'] ?? 0,
      activeUsers: json['activeUsers'] ?? 0,
      salesCount: json['salesCount'] ?? 0,
      revenue: (json['revenue'] ?? 0.0).toDouble(),
      productsCount: json['productsCount'] ?? 0,
      clientsCount: json['clientsCount'] ?? 0,
    );
  }
}

class AdminService {
  /// Busca todas as lojas
  static Future<List<StoreInfo>> getStores() async {
    try {
      final response = await ApiClient.get('/admin/stores', auth: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => StoreInfo.fromJson(json)).toList();
      }
      throw Exception('Erro ao buscar lojas');
    } catch (e) {
      throw Exception('Erro ao buscar lojas: $e');
    }
  }

  /// Busca estatísticas globais (todas as lojas)
  static Future<StoreStats> getGlobalStats() async {
    try {
      final response = await ApiClient.get('/admin/stats', auth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StoreStats.fromJson(data);
      }
      throw Exception('Erro ao buscar estatísticas globais');
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas globais: $e');
    }
  }

  /// Busca estatísticas de uma loja específica
  static Future<StoreStats> getStoreStats(String storeId) async {
    try {
      final response = await ApiClient.get('/admin/stats/$storeId', auth: true);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return StoreStats.fromJson(data);
      }
      throw Exception('Erro ao buscar estatísticas da loja');
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas da loja: $e');
    }
  }

  /// Busca usuários de uma loja específica
  static Future<List<Map<String, dynamic>>> getStoreUsers(String storeId) async {
    try {
      final response = await ApiClient.get('/users?storeId=$storeId', auth: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Erro ao buscar usuários da loja');
    } catch (e) {
      throw Exception('Erro ao buscar usuários da loja: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> listUsers() async {
    final resp = await ApiClient.get('/users', auth: true);
    if (resp.statusCode != 200) return [];
    final List<dynamic> data = jsonDecode(resp.body);
    return data.cast<Map<String, dynamic>>();
  }

  static Future<Map<String, dynamic>?> updateUser(String userId, {
    String? role,
    String? status,
    String? storeId,
    String? blockedUntil,
    String? storeName,
  }) async {
    final body = <String, dynamic>{};
    if (role != null) body['role'] = role;
    if (status != null) body['status'] = status;
    if (storeId != null) body['storeId'] = storeId;
    if (blockedUntil != null) body['blockedUntil'] = blockedUntil;
    if (storeName != null) body['storeName'] = storeName;
    final resp = await ApiClient.patch('/users/$userId', body, auth: true);
    if (resp.statusCode != 200) return null;
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  /// Busca produtos de uma loja específica
  static Future<List<Map<String, dynamic>>> getStoreProducts(String storeId) async {
    try {
      final response = await ApiClient.get('/products?storeId=$storeId', auth: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Erro ao buscar produtos da loja');
    } catch (e) {
      throw Exception('Erro ao buscar produtos da loja: $e');
    }
  }

  /// Busca vendas de uma loja específica
  static Future<List<Map<String, dynamic>>> getStoreSales(String storeId) async {
    try {
      final response = await ApiClient.get('/sales?storeId=$storeId', auth: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Erro ao buscar vendas da loja');
    } catch (e) {
      throw Exception('Erro ao buscar vendas da loja: $e');
    }
  }

  /// Busca clientes de uma loja específica
  static Future<List<Map<String, dynamic>>> getStoreClients(String storeId) async {
    try {
      final response = await ApiClient.get('/clients?storeId=$storeId', auth: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Erro ao buscar clientes da loja');
    } catch (e) {
      throw Exception('Erro ao buscar clientes da loja: $e');
    }
  }

  /// Cria usuário em uma loja específica
  static Future<Map<String, dynamic>> createStoreUser({
    required String storeId,
    required String name,
    required String email,
    required String password,
    String role = 'user',
  }) async {
    try {
      final response = await ApiClient.post('/users', {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'storeId': storeId,
      }, auth: true);

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      throw Exception('Erro ao criar usuário');
    } catch (e) {
      throw Exception('Erro ao criar usuário: $e');
    }
  }

  /// Bloqueia usuário (admin não pode se bloquear)
  static Future<void> blockUser(String userId) async {
    try {
      final response = await ApiClient.patch('/users/$userId/block', {}, auth: true);
      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        if (error['error'] == 'cannot_block_self') {
          throw Exception('Você não pode se bloquear');
        }
        throw Exception('Erro ao bloquear usuário');
      }
    } catch (e) {
      throw Exception('Erro ao bloquear usuário: $e');
    }
  }

  /// Desbloqueia usuário
  static Future<void> unblockUser(String userId) async {
    try {
      final response = await ApiClient.patch('/users/$userId/unblock', {}, auth: true);
      if (response.statusCode != 200) {
        throw Exception('Erro ao desbloquear usuário');
      }
    } catch (e) {
      throw Exception('Erro ao desbloquear usuário: $e');
    }
  }
}
