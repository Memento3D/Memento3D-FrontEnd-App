import 'dart:convert';
import '../utils/error_mapper.dart';

/// Represents an API or network error with standardized ERR-xxx codes
class ApiException implements Exception {
  final int statusCode;
  final String errorCode;
  final String message;
  final String? path;
  final Map<String, String>? validationErrors;

  ApiException({
    required this.statusCode,
    this.errorCode = 'ERR-017',
    required this.message,
    this.path,
    this.validationErrors,
  });

  /// Factory constructor to parse Backend ErrorResponse
  factory ApiException.fromResponse(int statusCode, String body) {
    String rawMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    String? backendErrorCode;
    String? path;
    Map<String, String>? validationErrors;

    try {
      if (body.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(body);
        if (json.containsKey('message') && json['message'] != null) {
          rawMessage = json['message'].toString();
        }
        if (json.containsKey('error_code') && json['error_code'] != null) {
          backendErrorCode = json['error_code'].toString();
        } else if (json.containsKey('errorCode') && json['errorCode'] != null) {
          backendErrorCode = json['errorCode'].toString();
        }
        if (json.containsKey('path') && json['path'] != null) {
          path = json['path'].toString();
        }
        if (json.containsKey('validationErrors') && json['validationErrors'] is Map) {
          validationErrors = (json['validationErrors'] as Map).map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          );
        }
      }
    } catch (_) {
      // If parsing fails, fall back to default
    }

    final resolvedErrorCode = ErrorMapper.resolveErrorCode(
      backendErrorCode: backendErrorCode,
      statusCode: statusCode,
      rawMessage: rawMessage,
    );

    final friendlyMessage = ErrorMapper.map(
      errorCode: resolvedErrorCode,
      statusCode: statusCode,
      rawMessage: rawMessage,
      validationErrors: validationErrors,
    );

    return ApiException(
      statusCode: statusCode,
      errorCode: resolvedErrorCode,
      message: friendlyMessage,
      path: path,
      validationErrors: validationErrors,
    );
  }

  @override
  String toString() => '[$errorCode] $message';
}
