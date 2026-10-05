import 'dart:async';

import 'package:memento3d_frontend_app/features/auth/data/services/password_recovery_service.dart';

class RecoveryTestService implements PasswordRecoveryService {
  RecoveryTestService({
    this.onEmail,
    this.result = ForgotPasswordResult.accepted,
  });
  final void Function(String)? onEmail;
  ForgotPasswordResult result;
  Completer<ForgotPasswordResult>? pending;
  bool throws = false;
  int calls = 0;
  @override
  Future<ForgotPasswordResult> requestReset(String email) async {
    calls++;
    onEmail?.call(email);
    if (throws) throw StateError('Sensitive backend message');
    return pending == null ? result : pending!.future;
  }

  ResetPasswordResult resetResult = ResetPasswordResult.accepted;
  Completer<ResetPasswordResult>? resetPending;
  bool resetThrows = false;
  int resetCalls = 0;
  final resetArguments = <({String token, String newPassword})>[];

  @override
  Future<ResetPasswordResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    resetCalls++;
    resetArguments.add((token: token, newPassword: newPassword));
    if (resetThrows) throw StateError('Sensitive reset backend message');
    return resetPending == null ? resetResult : resetPending!.future;
  }
}
