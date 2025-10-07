import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _userRoleKey = 'user_role';
  static const String _storeIdKey = 'store_id';
  static const String _storeNameKey = 'store_name';

  // Dados de usuários locais (em um app real, isso viria de um banco de dados)
  static final Map<String, Map<String, String>> _users = {
    'admin@nova.com': {'password': '123456', 'name': 'Administrador'},
    'lojista@nova.com': {'password': 'lojista123', 'name': 'Lojista'},
    'teste@nova.com': {'password': 'teste123', 'name': 'Usuário Teste'},
  };

  // Verificar se o usuário está logado
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Fazer login
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final resp = await ApiClient.post('/auth/login', {
      'email': email,
      'password': password,
    });
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = data['user'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      final emailStr = user['email'] as String;
      final roleStr = (user['role'] as String?) ?? 'user';
      final storeIdStr = (user['storeId'] as String?) ?? '';
      final storeNameStr = (user['storeName'] as String?) ?? '';
      final displayName =
          (user['name'] as String?) ?? emailStr.split('@').first;
      await prefs.setString(_userEmailKey, emailStr);
      await prefs.setString(_userNameKey, displayName);
      await prefs.setString(_userRoleKey, roleStr);
      if (storeIdStr.isNotEmpty) {
        await prefs.setString(_storeIdKey, storeIdStr);
      }
      if (storeNameStr.isNotEmpty) {
        await prefs.setString(_storeNameKey, storeNameStr);
      }
      await ApiClient.saveToken(token);
      return {
        'success': true,
        'message': 'Login realizado com sucesso!',
        'user': user,
      };
    }
    if (resp.statusCode == 401) {
      return {'success': false, 'message': 'Credenciais inválidas'};
    }
    if (resp.statusCode == 403) {
      try {
        final err = jsonDecode(resp.body) as Map<String, dynamic>;
        final code = err['error'] as String?;
        if (code == 'account_blocked_until') {
          return {
            'success': false,
            'message':
                'Conta bloqueada temporariamente. Contacte o administrador: +245956605604',
          };
        }
      } catch (_) {}
      return {
        'success': false,
        'message': 'Conta bloqueada. Contacte o administrador: +245956605604',
      };
    }
    return {'success': false, 'message': 'Erro ao fazer login'};
  }

  // Fazer logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_storeIdKey);
    await ApiClient.clearToken();
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  // Obter dados do usuário logado
  static Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;

    if (isLoggedIn) {
      final email = prefs.getString(_userEmailKey) ?? '';
      final name = prefs.getString(_userNameKey) ?? '';
      final storeId = prefs.getString(_storeIdKey) ?? '';
      return {'email': email, 'name': name, 'storeId': storeId};
    }
    return null;
  }

  // Cadastrar novo usuário (funcionalidade básica)
  static Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
  ) async {
    // Simular delay de rede
    await Future.delayed(const Duration(seconds: 1));

    // Verificar se o email já existe
    if (_users.containsKey(email)) {
      return {'success': false, 'message': 'Este email já está cadastrado'};
    }

    // Validar dados
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      return {'success': false, 'message': 'Todos os campos são obrigatórios'};
    }

    if (password.length < 6) {
      return {
        'success': false,
        'message': 'A senha deve ter pelo menos 6 caracteres',
      };
    }

    // Cadastrar usuário
    _users[email] = {'password': password, 'name': name};

    return {'success': true, 'message': 'Usuário cadastrado com sucesso!'};
  }

  // Alterar senha
  static Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = await getCurrentUser();
    if (user == null) {
      return {'success': false, 'message': 'Usuário não está logado'};
    }

    final email = user['email']!;
    if (_users[email]!['password'] != currentPassword) {
      return {'success': false, 'message': 'Senha atual incorreta'};
    }

    if (newPassword.length < 6) {
      return {
        'success': false,
        'message': 'A nova senha deve ter pelo menos 6 caracteres',
      };
    }

    _users[email]!['password'] = newPassword;

    return {'success': true, 'message': 'Senha alterada com sucesso!'};
  }

  // Recuperar senha (simulação)
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    // Simular delay de rede
    await Future.delayed(const Duration(seconds: 2));

    if (_users.containsKey(email)) {
      return {
        'success': true,
        'message': 'Instruções de recuperação enviadas para $email',
      };
    } else {
      return {'success': false, 'message': 'Email não encontrado'};
    }
  }
}
