import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/auth/data/models/email_verification_result.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/email_verification_state.dart';

class _Service implements EmailVerificationService {
  Future<EmailVerificationResult> Function(String) verify = (_) async =>
      EmailVerificationResult.success;
  Future<EmailResendResult> Function(String) send = (_) async =>
      const EmailResendResult.sent();
  int verifies = 0;
  int resends = 0;

  @override
  Future<EmailVerificationResult> verifyToken(String token) {
    verifies++;
    return verify(token);
  }

  @override
  Future<EmailResendResult> resend(String email) {
    resends++;
    return send(email);
  }
}

void main() {
  test('successful resend has no invented cooldown', () async {
    final state = EmailVerificationState(
      service: _Service(),
      email: 'bach@example.com',
    );
    addTearDown(state.dispose);
    expect(state.status, EmailVerificationStatus.waiting);
    expect(state.canResend, isTrue);
    await state.resend();
    expect(state.feedback, EmailVerificationFeedback.resendSent);
    expect(state.retryAt, isNull);
    expect(state.remainingSeconds, 0);
    expect(state.canResend, isTrue);
  });

  test(
    'deadline rounds up, recalculates and preserves invalid recovery',
    () async {
      var now = DateTime.utc(2026, 1, 1);
      final deadline = now.add(const Duration(milliseconds: 2500));
      final state = EmailVerificationState(
        email: 'bach@example.com',
        now: () => now,
        service: (_Service()
          ..verify = ((_) async => EmailVerificationResult.invalidOrExpired)
          ..send = (_) async => EmailResendResult.rateLimited(deadline)),
      );
      addTearDown(state.dispose);
      await state.verifyToken('test');
      await state.resend();
      expect(state.status, EmailVerificationStatus.rateLimited);
      expect(state.phase, EmailVerificationStatus.invalidOrExpired);
      expect(state.remainingSeconds, 3);
      expect(state.canResend, isFalse);
      now = now.add(const Duration(seconds: 2));
      state.refreshTime();
      expect(state.remainingSeconds, 1);
      now = deadline;
      state.refreshTime();
      expect(state.remainingSeconds, 0);
      expect(state.canResend, isTrue);
      expect(state.status, EmailVerificationStatus.invalidOrExpired);
    },
  );

  test('token verification is allowed during resend cooldown', () async {
    final state = EmailVerificationState(
      email: 'bach@example.com',
      service: (_Service()
        ..send = (_) async => EmailResendResult.rateLimited(
          DateTime.now().add(const Duration(days: 1)),
        )),
    );
    addTearDown(state.dispose);
    await state.resend();
    expect(state.status, EmailVerificationStatus.rateLimited);
    await state.verifyToken('test');
    expect(state.status, EmailVerificationStatus.success);
    expect(state.retryAt, isNull);
  });

  test('resend and verification requests are deduplicated', () async {
    final resend = Completer<EmailResendResult>();
    final verify = Completer<EmailVerificationResult>();
    final service = _Service();
    service.send = (_) => resend.future;
    service.verify = (_) => verify.future;
    final state = EmailVerificationState(
      service: service,
      email: 'bach@example.com',
    );
    addTearDown(state.dispose);
    final pendingSend = state.resend();
    await state.resend();
    expect(service.resends, 1);
    expect(state.isResending, isTrue);
    final pendingVerify = state.verifyToken('private');
    await state.verifyToken('private');
    expect(service.verifies, 1);
    expect(state.status, EmailVerificationStatus.verifying);
    verify.complete(EmailVerificationResult.success);
    await pendingVerify;
    resend.complete(const EmailResendResult.sent());
    await pendingSend;
    expect(state.status, EmailVerificationStatus.success);
    expect(state.feedback, isNull);
  });

  test(
    'generic verify failure preserves phase and retry can succeed',
    () async {
      final service = _Service()
        ..verify = (_) async => throw StateError('offline');
      final state = EmailVerificationState(
        service: service,
        email: 'bach@example.com',
      );
      addTearDown(state.dispose);
      await state.verifyToken('private');
      expect(state.status, EmailVerificationStatus.waiting);
      expect(state.feedback, EmailVerificationFeedback.verificationFailed);
      expect(state.canRetryVerification, isTrue);
      service.verify = (token) async {
        expect(token, 'private');
        return EmailVerificationResult.success;
      };
      await state.retryVerification();
      expect(state.status, EmailVerificationStatus.success);
      expect(state.canRetryVerification, isFalse);
    },
  );

  test(
    'generic resend failure can retry and does not invalidate token',
    () async {
      final service = _Service()
        ..send = (_) async => throw StateError('offline');
      final state = EmailVerificationState(
        service: service,
        email: 'bach@example.com',
      );
      addTearDown(state.dispose);
      await state.resend();
      expect(state.phase, EmailVerificationStatus.waiting);
      expect(state.feedback, EmailVerificationFeedback.resendFailed);
      expect(state.canResend, isTrue);
      service.send = (_) async => const EmailResendResult.sent();
      await state.resend();
      expect(state.feedback, EmailVerificationFeedback.resendSent);
    },
  );

  test('explicit invalid result is recoverable by successful resend', () async {
    final state = EmailVerificationState(
      email: 'bach@example.com',
      service: (_Service()
        ..verify = ((_) async => EmailVerificationResult.invalidOrExpired)),
    );
    addTearDown(state.dispose);
    await state.verifyToken('expired');
    expect(state.phase, EmailVerificationStatus.invalidOrExpired);
    await state.resend();
    expect(state.phase, EmailVerificationStatus.waiting);
    expect(state.feedback, EmailVerificationFeedback.resendSent);
  });

  test('missing email prevents resend but still accepts a token', () async {
    final service = _Service();
    final state = EmailVerificationState(service: service);
    addTearDown(state.dispose);
    await state.resend();
    expect(service.resends, 0);
    await state.verifyToken('test');
    expect(state.status, EmailVerificationStatus.success);
  });

  test('disposed controller ignores pending service completion', () async {
    final pending = Completer<EmailVerificationResult>();
    final service = _Service()..verify = (_) => pending.future;
    final state = EmailVerificationState(service: service);
    var notifications = 0;
    state.addListener(() => notifications++);
    final work = state.verifyToken('test');
    expect(notifications, 1);
    state.dispose();
    pending.complete(EmailVerificationResult.success);
    await work;
    expect(notifications, 1);
  });
}
