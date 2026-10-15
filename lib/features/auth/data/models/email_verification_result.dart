/// Frontend outcomes, not a guessed backend response schema.
enum EmailVerificationResult { success, invalidOrExpired }

class EmailResendResult {
  const EmailResendResult.sent() : retryAt = null;
  const EmailResendResult.rateLimited(DateTime deadline) : retryAt = deadline;

  final DateTime? retryAt;
}

abstract class EmailVerificationService {
  Future<EmailVerificationResult> verifyToken(String token);
  Future<EmailResendResult> resend(String email);
}
