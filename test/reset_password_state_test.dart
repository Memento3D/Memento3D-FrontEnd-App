import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/password_recovery_service.dart';
import 'package:memento3d_frontend_app/features/auth/presentation/controllers/reset_password_state.dart';

import 'recovery_test_service.dart';

const _token = 'SUPER_SECRET_RESET_TOKEN_123';
const _password = ' Private Password1! ';

void main() {
  late RecoveryTestService service;
  late ResetPasswordState state;
  setUp(() {
    service = RecoveryTestService();
    state = ResetPasswordState(service);
  });
  tearDown(() => state.dispose());
  Future<void> submit() => state.submit(token: _token, newPassword: _password);

  test('initial state is editing; outcomes are minimal', () {
    expect(state.status, ResetPasswordStatus.editing);
    expect(state.isSubmitting, isFalse);
    expect(ResetPasswordResult.values, [
      ResetPasswordResult.accepted,
      ResetPasswordResult.recoverableFailure,
      ResetPasswordResult.invalidOrExpired,
    ]);
  });
  test('submit synchronously enters submitting', () async {
    service.resetPending = Completer();
    final request = submit();
    expect(state.status, ResetPasswordStatus.submitting);
    expect(state.isSubmitting, isTrue);
    service.resetPending!.complete(ResetPasswordResult.accepted);
    await request;
  });
  test('accepted result reaches accepted and cannot resubmit', () async {
    await submit();
    expect(state.status, ResetPasswordStatus.accepted);
    expect(state.isSubmitting, isFalse);
    await submit();
    expect(service.resetCalls, 1);
  });
  test('recoverable result reaches generic failure', () async {
    service.resetResult = ResetPasswordResult.recoverableFailure;
    await submit();
    expect(state.status, ResetPasswordStatus.recoverableFailure);
  });
  test('thrown exception is sanitized into generic failure', () async {
    service.resetThrows = true;
    await submit();
    expect(state.status, ResetPasswordStatus.recoverableFailure);
    expect(
      state.toString(),
      isNot(contains('Sensitive reset backend message')),
    );
  });
  test('pending duplicate submits invoke service only once', () async {
    service.resetPending = Completer();
    final request = submit();
    await submit();
    expect(service.resetCalls, 1);
    service.resetPending!.complete(ResetPasswordResult.accepted);
    await request;
  });
  test('retry after failure succeeds with new exact arguments', () async {
    service.resetResult = ResetPasswordResult.recoverableFailure;
    await submit();
    service.resetResult = ResetPasswordResult.accepted;
    await state.submit(token: 'another-token', newPassword: 'x');
    expect(state.status, ResetPasswordStatus.accepted);
    expect(service.resetCalls, 2);
    expect(service.resetArguments.last, (
      token: 'another-token',
      newPassword: 'x',
    ));
  });
  for (final result in ResetPasswordResult.values) {
    test('pending $result completion after dispose is ignored', () async {
      final localService = RecoveryTestService()..resetPending = Completer();
      final localState = ResetPasswordState(localService);
      var notifications = 0;
      localState.addListener(() => notifications++);
      final request = localState.submit(token: _token, newPassword: _password);
      localState.dispose();
      localService.resetPending!.complete(result);
      await request;
      expect(notifications, 1);
      expect(localState.status, ResetPasswordStatus.submitting);
      await localState.submit(token: _token, newPassword: _password);
      expect(localService.resetCalls, 1);
    });
  }
  test('exception completion after disposal is safe', () async {
    final localService = RecoveryTestService()..resetPending = Completer();
    final localState = ResetPasswordState(localService);
    final request = localState.submit(token: _token, newPassword: _password);
    localState.dispose();
    localService.resetPending!.completeError(StateError('sensitive'));
    await request;
    expect(localState.status, ResetPasswordStatus.submitting);
  });
  test(
    'request arguments are exact and status notifications contain no secrets',
    () async {
      final statuses = <ResetPasswordStatus>[];
      state.addListener(() => statuses.add(state.status));
      await submit();
      expect(service.resetArguments.single, (
        token: _token,
        newPassword: _password,
      ));
      expect(statuses, [
        ResetPasswordStatus.submitting,
        ResetPasswordStatus.accepted,
      ]);
      expect(state.toString(), isNot(contains(_token)));
      expect(state.toString(), isNot(contains(_password)));
    },
  );
  test('unavailable frontend service cannot simulate reset success', () async {
    final localState = ResetPasswordState(
      const UnavailablePasswordRecoveryService(),
    );
    await localState.submit(token: _token, newPassword: _password);
    expect(localState.status, ResetPasswordStatus.recoverableFailure);
    localState.dispose();
  });
  test(
    'invalid/expired outcome is terminal and cannot retry the old token',
    () async {
      service.resetResult = ResetPasswordResult.invalidOrExpired;
      await submit();
      expect(state.status, ResetPasswordStatus.invalidOrExpired);
      expect(state.isTerminal, isTrue);
      await submit();
      expect(service.resetCalls, 1);
    },
  );
  for (final token in <String?>[null, '', '   ']) {
    test(
      'missing or blank token fails safely without service call: $token',
      () async {
        await state.submit(token: token, newPassword: _password);
        expect(state.status, ResetPasswordStatus.invalidOrExpired);
        expect(service.resetCalls, 0);
      },
    );
  }
  test('screen can initialize invalid status without retaining a token', () {
    final localState = ResetPasswordState(service, hasToken: false);
    expect(localState.status, ResetPasswordStatus.invalidOrExpired);
    localState.dispose();
  });
}
