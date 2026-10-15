import 'package:flutter/foundation.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/features/auth/data/models/user_model.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/auth_service.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/auth_storage.dart';

import 'package:memento3d_frontend_app/core/network/api_client.dart';

/// Global authentication state management (corresponds to useAuthStore in FRONTEND_ARCHITECTURE.md)
class AuthState extends ChangeNotifier {
  static final AuthState instance = AuthState._internal();
  factory AuthState() => instance;
  AuthState._internal();

  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  String? _accessToken;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  /// Load cached user & token on app startup and verify session with backend in background
  Future<void> initialize() async {
    // Interceptor: automatic session invalidation on 401 Unauthorized
    ApiClient.onUnauthorized = () => clearSession();

    _currentUser = await AuthStorage.getUser();
    _accessToken = await AuthStorage.getToken();
    notifyListeners();

    _verifySessionInBackground();
  }

  /// Sets user profile and access token (implements setSession from FRONTEND_ARCHITECTURE.md)
  Future<void> setSession(UserModel user, String token) async {
    _currentUser = user;
    _accessToken = token;
    await AuthStorage.saveToken(token);
    await AuthStorage.saveUser(user);
    notifyListeners();
  }

  /// Clears user profile and access token (implements clearSession from FRONTEND_ARCHITECTURE.md)
  Future<void> clearSession() async {
    _currentUser = null;
    _accessToken = null;
    await AuthStorage.clearAuthData();
    notifyListeners();
  }

  /// Verifies active session with backend asynchronously without blocking app startup
  void _verifySessionInBackground() async {
    final token = await AuthStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final user = await _authService.getCurrentUser();
        if (user != _currentUser) {
          _currentUser = user;
          _accessToken = user != null ? token : null;
          notifyListeners();
        }
      } catch (_) {
        // Offline or server unreachable: retain cached profile
      }
    }
  }

  /// Perform login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email: email, password: password);
      _currentUser = result.user;
      _accessToken = result.accessToken;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Publish the server-confirmed profile to all consumers.
  Future<void> updateProfile(String fullName) async {
    _currentUser = await _authService.updateProfile(fullName: fullName);
    notifyListeners();
  }

  /// Perform registration
  Future<RegisterResponseModel?> register({
    required String email,
    required String password,
    required String fullName,
    required bool agreeTerms,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        email: email,
        password: password,
        fullName: fullName,
        agreeTerms: agreeTerms,
      );
      _isLoading = false;
      notifyListeners();
      return response;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại.';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Perform logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    _currentUser = null;
    _accessToken = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear any existing error message
  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
