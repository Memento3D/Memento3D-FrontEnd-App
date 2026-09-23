import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/core/network/api_config.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import '../models/user_model.dart';
import 'auth_storage.dart';

/// Service for authentication operations interacting with Backend API
class AuthService {
  final ApiClient _apiClient;

  AuthService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Log in with email and password
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.login,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    final authResponse = AuthResponseModel.fromJson(response as Map<String, dynamic>);

    // Persist token and user profile
    await AuthStorage.saveToken(authResponse.accessToken);
    if (authResponse.user != null) {
      await AuthStorage.saveUser(authResponse.user!);
    }

    return authResponse;
  }

  /// Register a new account
  Future<RegisterResponseModel> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.register,
      body: {
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
      },
    );

    return RegisterResponseModel.fromJson(response as Map<String, dynamic>);
  }

  /// Retrieve the current user's profile using the stored JWT
  Future<UserModel?> getCurrentUser() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await _apiClient.get(
        ApiConfig.currentUser,
        token: token,
      );

      final user = UserModel.fromJson(response as Map<String, dynamic>);
      await AuthStorage.saveUser(user);
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        // Token is invalid, expired, or blacklisted -> wipe stored session
        await AuthStorage.clearAuthData();
        return null;
      }
      // If server error occurs, fallback to locally cached user
      return await AuthStorage.getUser();
    } catch (_) {
      // If offline or network connection fails, return currently cached user if any
      return await AuthStorage.getUser();
    }
  }

  /// Log out and invalidate JWT session
  Future<void> logout() async {
    final token = await AuthStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _apiClient.post(
          ApiConfig.logout,
          token: token,
        );
      } catch (_) {
        // Even if server call fails (e.g. offline), clear local session
      }
    }

    await AuthStorage.clearAuthData();
  }
}
