import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';

/// Frontend outcomes only; neither outcome describes account existence.
enum ForgotPasswordResult { accepted, recoverableFailure }

enum ResetPasswordResult { accepted, recoverableFailure, invalidOrExpired }

abstract interface class PasswordRecoveryService {
  Future<ForgotPasswordResult> requestReset(String email);

  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
  });
}

/// Safe frontend fallback until a production recovery service is supplied.
class UnavailablePasswordRecoveryService implements PasswordRecoveryService {
  const UnavailablePasswordRecoveryService();

  @override
  Future<ForgotPasswordResult> requestReset(String email) async =>
      ForgotPasswordResult.recoverableFailure;

  @override
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
  }) async => ResetPasswordResult.recoverableFailure;
}

class ApiPasswordRecoveryService implements PasswordRecoveryService {
  const ApiPasswordRecoveryService({this.client});

  final ApiClient? client;

  @override
  Future<ForgotPasswordResult> requestReset(String email) async {
    try {
      await (client ?? ApiClient()).post(
        '/api/v1/auth/forgot-password',
        body: {'email': email.trim()},
      );
      return ForgotPasswordResult.accepted;
    } on ApiException {
      return ForgotPasswordResult.recoverableFailure;
    }
  }

  @override
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await (client ?? ApiClient()).post(
        '/api/v1/auth/reset-password',
        body: {'token': token, 'newPassword': newPassword},
      );
      return ResetPasswordResult.accepted;
    } on ApiException catch (error) {
      return error.backendCode == 'INVALID_RESET_TOKEN'
          ? ResetPasswordResult.invalidOrExpired
          : ResetPasswordResult.recoverableFailure;
    }
  }
}
