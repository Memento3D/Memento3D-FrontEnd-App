import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Service for persisting authentication credentials and user profile
class AuthStorage {
  static const String _keyToken = 'memento3d_access_token';
  static const String _keyUser = 'memento3d_user_data';

  // In-memory fallback in case persistent storage has issues
  static String? _inMemoryToken;
  static UserModel? _inMemoryUser;

  /// Save JWT token
  static Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
    } catch (_) {
      // In-memory fallback
    }
  }

  /// Retrieve stored JWT token
  static Future<String?> getToken() async {
    if (_inMemoryToken != null) {
      return _inMemoryToken;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _inMemoryToken = prefs.getString(_keyToken);
      return _inMemoryToken;
    } catch (_) {
      return _inMemoryToken;
    }
  }

  /// Save user profile
  static Future<void> saveUser(UserModel user) async {
    _inMemoryUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (_) {
      // In-memory fallback
    }
  }

  /// Retrieve stored user profile
  static Future<UserModel?> getUser() async {
    if (_inMemoryUser != null) {
      return _inMemoryUser;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_keyUser);
      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        _inMemoryUser = UserModel.fromJson(jsonDecode(userJsonStr));
        return _inMemoryUser;
      }
    } catch (_) {
      return _inMemoryUser;
    }
    return null;
  }

  /// Clear all stored auth data (used on logout)
  static Future<void> clearAuthData() async {
    _inMemoryToken = null;
    _inMemoryUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (_) {
      // In-memory cleared
    }
  }
}
