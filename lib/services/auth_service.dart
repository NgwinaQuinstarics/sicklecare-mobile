import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await ApiService.post('/login', {
      'email': email, 'password': password,
    });
    if (res['success'] == true) {
      await ApiService.saveToken(res['data']['token']);
    }
    return res;
  }

  static Future<Map<String, dynamic>> register(
      String name, String email, String password, String confirm) async {
    final res = await ApiService.post('/register', {
      'name': name, 'email': email,
      'password': password, 'password_confirmation': confirm,
    });
    if (res['success'] == true) {
      await ApiService.saveToken(res['data']['token']);
    }
    return res;
  }

  static Future<void> logout() async {
    try { await ApiService.post('/logout', {}, auth: true); } catch (_) {}
    await ApiService.clearToken();
  }

  static Future<UserModel?> getProfile() async {
    try {
      final res = await ApiService.get('/user');
      if (res['success'] == true) return UserModel.fromJson(res['data']);
    } catch (_) {}
    return null;
  }

  static Future<bool> isLoggedIn() => ApiService.hasToken();
}
