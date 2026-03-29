import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();

  static Future<String?> _getToken() async =>
      _storage.read(key: AppConfig.tokenKey);

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (auth) {
      final t = await _getToken();
      if (t != null) h['Authorization'] = 'Bearer $t';
    }
    return h;
  }

  static Future<Map<String, dynamic>> post(
    String path, Map<String, dynamic> body, {bool auth = false}
  ) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: await _headers(auth: auth),
      body: jsonEncode(body),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final res = await http.get(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: await _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> delete(String path) async {
    final res = await http.delete(
      Uri.parse('${AppConfig.apiBaseUrl}$path'),
      headers: await _headers(),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<void> saveToken(String token) =>
      _storage.write(key: AppConfig.tokenKey, value: token);

  static Future<void> clearToken() =>
      _storage.delete(key: AppConfig.tokenKey);

  static Future<bool> hasToken() async =>
      (await _getToken()) != null;
}
