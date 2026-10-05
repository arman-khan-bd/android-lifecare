import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyCustomDomain = 'custom_base_url';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final customDomain = prefs.getString(_keyCustomDomain);
    if (customDomain != null && customDomain.isNotEmpty && !customDomain.contains('boosterdose')) {
      ApiConfig.baseUrl = ApiConfig.sanitizeUrl(customDomain);
    } else {
      ApiConfig.baseUrl = ApiConfig.defaultBaseUrl;
      await prefs.setString(_keyCustomDomain, ApiConfig.defaultBaseUrl);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_keyUser);
    if (userJson == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(userJson));
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  static Future<void> setBaseUrl(String url) async {
    final cleanUrl = ApiConfig.sanitizeUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomDomain, cleanUrl);
    ApiConfig.baseUrl = cleanUrl;
  }
}
