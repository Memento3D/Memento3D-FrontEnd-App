import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../features/auth/data/services/auth_storage.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Base HTTP client for sending requests to Memento3D backend
class ApiClient {
  final http.Client _httpClient;

  /// Global interceptor callback triggered on HTTP 401 Unauthorized (Token Rotation / Expiration)
  static void Function()? onUnauthorized;

  ApiClient({http.Client? client}) : _httpClient = client ?? http.Client();

  /// Sends once through the injected client. A timeout does not cancel or undo
  /// the server operation; callers must not automatically replay this POST.
  Future<dynamic> postMultipart(
    String endpoint, {
    required List<http.MultipartFile> files,
    Map<String, String> fields = const {},
    String? token,
    Map<String, String>? headers,
    int? expectedStatusCode,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}$endpoint'),
    );
    final resolved = await _buildHeaders(
      token: token,
      additionalHeaders: headers,
    );
    resolved.removeWhere((key, _) => key.toLowerCase() == 'content-type');
    request.headers.addAll(resolved);
    request.fields.addAll(fields);
    request.files.addAll(files);
    request.followRedirects = false;
    try {
      final response = await (() async {
        final streamed = await _httpClient.send(request);
        return http.Response.fromStream(streamed);
      })().timeout(ApiConfig.timeout);
      final decoded = _handleResponse(response);
      if (expectedStatusCode != null &&
          response.statusCode != expectedStatusCode) {
        throw ApiException(
          statusCode: response.statusCode,
          message: 'Unexpected multipart success status',
        );
      }
      return decoded;
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'ERR-017',
        message: 'Network connection failed during multipart POST',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        errorCode: 'ERR-009',
        message: 'Multipart POST timed out; server outcome is unknown',
      );
    } catch (error) {
      if (error is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        errorCode: 'ERR-017',
        message: 'Multipart POST response unavailable',
      );
    }
  }

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    String? token,
    Map<String, String>? headers,
    int? expectedStatusCode,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final mergedHeaders = await _buildHeaders(
      token: token,
      additionalHeaders: headers,
    );

    try {
      final response = await _httpClient
          .get(uri, headers: mergedHeaders)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response, expectedStatusCode: expectedStatusCode);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'ERR-017',
        message:
            'Không thể kết nối đến máy chủ backend (${ApiConfig.baseUrl}). Vui lòng kiểm tra lại mạng hoặc đảm bảo backend đang chạy.',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        errorCode: 'ERR-009',
        message: 'Kết nối mạng quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        errorCode: 'ERR-017',
        message: 'Lỗi không xác định: ${e.toString()}',
      );
    }
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
    int? expectedStatusCode,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final mergedHeaders = await _buildHeaders(
      token: token,
      additionalHeaders: headers,
    );

    try {
      final response = await _httpClient
          .post(
            uri,
            headers: mergedHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response, expectedStatusCode: expectedStatusCode);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'ERR-017',
        message:
            'Không thể kết nối đến máy chủ backend (${ApiConfig.baseUrl}). Vui lòng kiểm tra lại mạng hoặc đảm bảo backend đang chạy.',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        errorCode: 'ERR-009',
        message: 'Kết nối mạng quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        errorCode: 'ERR-017',
        message: 'Lỗi không xác định: ${e.toString()}',
      );
    }
  }

  /// PATCH request
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final resolved = await _buildHeaders(
      token: token,
      additionalHeaders: headers,
    );
    try {
      final response = await _httpClient
          .put(uri, headers: resolved, body: jsonEncode(body))
          .timeout(ApiConfig.timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'Chưa nhận được kết quả lưu. Lựa chọn vẫn được giữ; bạn có thể thử lại.',
      );
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        message: 'Không kết nối được máy chủ để lưu thiết kế.',
      );
    }
  }

  /// PATCH request
  Future<dynamic> patch(
    String endpoint, {
    dynamic body,
    String? token,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final mergedHeaders = await _buildHeaders(
      token: token,
      additionalHeaders: headers,
    );

    try {
      final response = await _httpClient
          .patch(
            uri,
            headers: mergedHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'ERR-017',
        message:
            'Không thể kết nối đến máy chủ backend (${ApiConfig.baseUrl}). Vui lòng kiểm tra lại mạng hoặc đảm bảo backend đang chạy.',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        errorCode: 'ERR-009',
        message: 'Kết nối mạng quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        errorCode: 'ERR-017',
        message: 'Lỗi không xác định: ${e.toString()}',
      );
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    String? token,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    final mergedHeaders = await _buildHeaders(
      token: token,
      additionalHeaders: headers,
    );

    try {
      final response = await _httpClient
          .delete(uri, headers: mergedHeaders)
          .timeout(ApiConfig.timeout);

      return _handleResponse(response);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'ERR-017',
        message:
            'Không thể kết nối đến máy chủ backend (${ApiConfig.baseUrl}). Vui lòng kiểm tra lại mạng hoặc đảm bảo backend đang chạy.',
      );
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        errorCode: 'ERR-009',
        message: 'Kết nối mạng quá thời gian chờ (Timeout). Vui lòng thử lại.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(
        statusCode: -1,
        errorCode: 'ERR-017',
        message: 'Lỗi không xác định: ${e.toString()}',
      );
    }
  }

  /// Combine default headers with token and custom headers
  Future<Map<String, String>> _buildHeaders({
    String? token,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'ngrok-skip-browser-warning': 'true',
    };

    final effectiveToken = token ?? await AuthStorage.getToken();
    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $effectiveToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Parse response or throw ApiException (with 401 Interceptor)
  dynamic _handleResponse(http.Response response, {int? expectedStatusCode}) {
    final statusCode = response.statusCode;
    final bodyString = utf8.decode(response.bodyBytes);

    if (statusCode >= 200 && statusCode < 300) {
      if (expectedStatusCode != null && statusCode != expectedStatusCode) {
        throw ApiException(
          statusCode: statusCode,
          message: 'Unexpected HTTP success status',
        );
      }
      if (bodyString.isEmpty) {
        return null;
      }
      try {
        return jsonDecode(bodyString);
      } catch (_) {
        return bodyString;
      }
    }

    // Intercept 401 Unauthorized (session expired / revoked)
    if (statusCode == 401) {
      onUnauthorized?.call();
    }

    throw ApiException.fromResponse(statusCode, bodyString);
  }
}
