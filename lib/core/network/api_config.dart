/// Configuration for backend API connectivity
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://lively-diffusion-duvet.ngrok-free.dev',
  );

  // Endpoints
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String currentUser = '/api/auth/me';
  static const String logout = '/api/auth/logout';
  static const String refresh = '/api/auth/refresh';
  static const String scans = '/api/v1/scans';
  static const String jobs = '/api/v1/jobs';

  /// GET /api/v1/scans/{id}/outputs — generated output files (GLB, OBJ, ...) for a scan
  static String scanOutputs(String scanId) => '/api/v1/scans/$scanId/outputs';

  // Request timeout
  static const Duration timeout = Duration(seconds: 15);
}
