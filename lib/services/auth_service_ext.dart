import 'package:shared_preferences/shared_preferences.dart';

class AuthKeys {
  static const userRole = 'user_role';
  static const storeId = 'store_id';
  static const userName = 'user_name';
  static const userEmail = 'user_email';
  static const isLoggedIn = 'is_logged_in';
}

class AuthProfile {
  final String email;
  final String name;
  final String role;
  final String storeId;

  const AuthProfile({
    required this.email,
    required this.name,
    required this.role,
    required this.storeId,
  });

  bool get isAdmin => role == 'admin';

  static Future<AuthProfile?> current() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(AuthKeys.isLoggedIn) ?? false)) return null;
    final email = prefs.getString(AuthKeys.userEmail) ?? '';
    final name = prefs.getString(AuthKeys.userName) ?? '';
    final role = prefs.getString(AuthKeys.userRole) ?? 'user';
    final storeId = prefs.getString(AuthKeys.storeId) ?? '';
    if (email.isEmpty || storeId.isEmpty) return null;
    return AuthProfile(email: email, name: name, role: role, storeId: storeId);
  }
}


