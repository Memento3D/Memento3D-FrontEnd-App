import 'package:flutter/foundation.dart';

/// Configuration for backend API connectivity
class ApiConfig {
  /// Base URL can be overridden at runtime if needed (e.g. for testing on real devices)
  static String? customBaseUrl;

  /// Default port for Memento3D Spring Boot backend
  static const int defaultPort = 8080;

  /// Automatically resolves the correct base URL based on platform or environment variable
  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.isNotEmpty) {
      return customBaseUrl!;
    }

    // Support --dart-define=API_URL=http://...
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // In Flutter Web, localhost points to the browser host
    if (kIsWeb) {
      return 'http://localhost:$defaultPort';
    }

    // For Android Emulator, localhost is 10.0.2.2
    // For iOS Simulator, macOS, Windows, Linux, localhost is 127.0.0.1 / localhost
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$defaultPort';
    }

    return 'http://localhost:$defaultPort';
  }

  // Endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String currentUser = '/api/auth/me';
  static const String logout = '/api/auth/logout';
  static const String scans = '/api/v1/scans';
  static const String jobs = '/api/v1/jobs';

  // Request timeout
  static const Duration timeout = Duration(seconds: 15);
}
