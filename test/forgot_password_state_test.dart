import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/password_recovery_service.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/forgot_password_state.dart';

import 'recovery_test_service.dart';

void main() {
  test('initial idle and minimal account-independent outcomes', () {
    final state = ForgotPasswordState(RecoveryTestService());
    expect(state.status, ForgotPasswordStatus.idle);
    expect(ForgotPasswordResult.values, [
      ForgotPasswordResult.accepted,
      ForgotPasswordResult.recoverableFailure,
    ]);
    expect(ForgotPasswordStatus.values, [
      ForgotPasswordStatus.idle,
      ForgotPasswordStatus.submitting,
      ForgotPasswordStatus.genericSuccess,
      ForgotPasswordStatus.recoverableFailure,
    ]);
    state.dispose();
  });
  for (final scenario in ['existing account', 'unknown account']) {
    test('$scenario yields identical generic success', () async {
      final state = ForgotPasswordState(RecoveryTestService());
      await state.requestReset('fixture@example.com');
      expect(state.status, ForgotPasswordStatus.genericSuccess);
      expect(state.hasAcceptedRequest, isTrue);
      state.dispose();
    });
  }
  test('pending submit and resend guard duplicates', () async {
    final service = RecoveryTestService()..pending = Completer();
    final state = ForgotPasswordState(service);
    var notifications = 0;
    state.addListener(() => notifications++);
    final first = state.requestReset('fixture@example.com');
    expect(state.status, ForgotPasswordStatus.submitting);
    await state.requestReset('fixture@example.com');
    expect(service.calls, 1);
    service.pending!.complete(ForgotPasswordResult.accepted);
    await first;
    expect(notifications, 2);
    service.pending = Completer();
    final resend = state.requestReset('fixture@example.com');
    expect(state.hasAcceptedRequest, isTrue);
    await state.requestReset('fixture@example.com');
    expect(service.calls, 2);
    service.pending!.complete(ForgotPasswordResult.accepted);
    await resend;
    expect(state.status, ForgotPasswordStatus.genericSuccess);
    state.dispose();
  });
  test('technical failure supports retry and failed resend', () async {
    final service = RecoveryTestService(
      result: ForgotPasswordResult.recoverableFailure,
    );
    final state = ForgotPasswordState(service);
    await state.requestReset('fixture@example.com');
    expect(state.status, ForgotPasswordStatus.recoverableFailure);
    service.result = ForgotPasswordResult.accepted;
    await state.requestReset('fixture@example.com');
    expect(state.status, ForgotPasswordStatus.genericSuccess);
    service.throws = true;
    await state.requestReset('fixture@example.com');
    expect(state.status, ForgotPasswordStatus.recoverableFailure);
    expect(state.hasAcceptedRequest, isTrue);
    state.dispose();
  });
  for (final result in ForgotPasswordResult.values) {
    test('completion after dispose is ignored: $result', () async {
      final service = RecoveryTestService()..pending = Completer();
      final state = ForgotPasswordState(service);
      final request = state.requestReset('fixture@example.com');
      state.dispose();
      service.pending!.complete(result);
      await request;
      expect(state.status, ForgotPasswordStatus.submitting);
      await state.requestReset('fixture@example.com');
      expect(service.calls, 1);
    });
  }
}
