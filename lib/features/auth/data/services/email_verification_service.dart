import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../models/email_verification_result.dart';

class ApiEmailVerificationService implements EmailVerificationService {
  ApiEmailVerificationService({ApiClient? client})
    : _client = client ?? ApiClient();

  final ApiClient _client;

  @override
  Future<EmailVerificationResult> verifyToken(String token) async {
    try {
      final response = await _client.post(
        '/api/v1/auth/email/verify',
        body: {'token': token},
      );
      if (response is Map && response['verified'] == true) {
        return EmailVerificationResult.success;
      }
      throw const FormatException('Invalid verification response');
    } on ApiException catch (error) {
      if (error.statusCode == 400) {
        return EmailVerificationResult.invalidOrExpired;
      }
      rethrow;
    }
  }

  @override
  Future<EmailResendResult> resend(String email) async {
    try {
      await _client.post(
        '/api/v1/auth/email/resend-verification',
        body: {'email': email.trim()},
      );
      return const EmailResendResult.sent();
    } on ApiException catch (error) {
      if (error.statusCode == 429) {
        return EmailResendResult.rateLimited(
          DateTime.now().add(const Duration(seconds: 60)),
        );
      }
      rethrow;
    }
  }
}
