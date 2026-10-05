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
