import '../models/email_verification_result.dart';

enum MockVerificationOutcome { success, invalidOrExpired, failure }

enum MockResendOutcome { sent, rateLimited, failure }

/// Explicit local outcomes. No network, polling, delays, or generated timing.
class MockEmailVerificationService implements EmailVerificationService {
  const MockEmailVerificationService({
    this.verification = MockVerificationOutcome.success,
    this.resendOutcome = MockResendOutcome.sent,
    this.retryAt,
  }) : assert(
         resendOutcome != MockResendOutcome.rateLimited || retryAt != null,
       );

  final MockVerificationOutcome verification;
  final MockResendOutcome resendOutcome;
  final DateTime? retryAt;

  @override
  Future<EmailVerificationResult> verifyToken(String token) async {
    return switch (verification) {
      MockVerificationOutcome.success => EmailVerificationResult.success,
      MockVerificationOutcome.invalidOrExpired =>
        EmailVerificationResult.invalidOrExpired,
      MockVerificationOutcome.failure => throw StateError(
        'Mock verify failure',
      ),
    };
  }

  @override
  Future<EmailResendResult> resend(String email) async {
    return switch (resendOutcome) {
      MockResendOutcome.sent => const EmailResendResult.sent(),
      MockResendOutcome.rateLimited => EmailResendResult.rateLimited(retryAt!),
      MockResendOutcome.failure => throw StateError('Mock resend failure'),
    };
  }
}
