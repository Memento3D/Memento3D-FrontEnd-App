import 'package:flutter/foundation.dart';

import '../../data/services/password_recovery_service.dart';

enum ResetPasswordStatus {
  editing,
  submitting,
  accepted,
  recoverableFailure,
  invalidOrExpired,
}

/// Owns status only. Sensitive arguments are used for one request, never fields.
class ResetPasswordState extends ChangeNotifier {
  ResetPasswordState(this._service, {bool hasToken = true})
    : _status = hasToken
          ? ResetPasswordStatus.editing
          : ResetPasswordStatus.invalidOrExpired;

  final PasswordRecoveryService _service;
  ResetPasswordStatus _status;
  bool _disposed = false;

  ResetPasswordStatus get status => _status;
  bool get isSubmitting => _status == ResetPasswordStatus.submitting;

  bool get isTerminal =>
      _status == ResetPasswordStatus.accepted ||
      _status == ResetPasswordStatus.invalidOrExpired;

  Future<void> submit({
    required String? token,
    required String newPassword,
  }) async {
    if (_disposed || isSubmitting || isTerminal) {
      return;
    }
    if (token == null || token.trim().isEmpty) {
      _status = ResetPasswordStatus.invalidOrExpired;
      notifyListeners();
      return;
    }
    _status = ResetPasswordStatus.submitting;
    notifyListeners();
    ResetPasswordResult result;
    try {
      result = await _service.resetPassword(
        token: token,
        newPassword: newPassword,
      );
    } catch (_) {
      result = ResetPasswordResult.recoverableFailure;
    }
    if (_disposed) return;
    _status = switch (result) {
      ResetPasswordResult.accepted => ResetPasswordStatus.accepted,
      ResetPasswordResult.recoverableFailure =>
        ResetPasswordStatus.recoverableFailure,
      ResetPasswordResult.invalidOrExpired =>
        ResetPasswordStatus.invalidOrExpired,
    };
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
