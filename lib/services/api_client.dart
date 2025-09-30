import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  // Backend base URL (Render)
  static String get _baseUrl => 'https://nova-joct.onrender.com';

  static const String _tokenKey = 'auth_token';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<http.Response> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return http.post(uri, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> get(String path, {bool auth = false}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return http.get(uri, headers: headers);
  }

  static Future<http.Response> patch(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return http.patch(uri, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return http.put(uri, headers: headers, body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path, {bool auth = false}) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{};
    if (auth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return http.delete(uri, headers: headers);
  }
}
