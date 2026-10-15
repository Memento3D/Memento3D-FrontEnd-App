import 'package:flutter/foundation.dart';

import '../../data/services/password_recovery_service.dart';

enum ForgotPasswordStatus {
  idle,
  submitting,
  genericSuccess,
  recoverableFailure,
}

class ForgotPasswordState extends ChangeNotifier {
  ForgotPasswordState(this._service);

  final PasswordRecoveryService _service;
  ForgotPasswordStatus _status = ForgotPasswordStatus.idle;
  bool _disposed = false;
  bool _hasAcceptedRequest = false;

  ForgotPasswordStatus get status => _status;
  bool get isSubmitting => _status == ForgotPasswordStatus.submitting;
  bool get hasAcceptedRequest => _hasAcceptedRequest;

  Future<void> requestReset(String email) async {
    if (_disposed || isSubmitting) return;
    _status = ForgotPasswordStatus.submitting;
    notifyListeners();
    ForgotPasswordResult result;
    try {
      result = await _service.requestReset(email);
    } catch (_) {
      result = ForgotPasswordResult.recoverableFailure;
    }
    if (_disposed) return;
    if (result == ForgotPasswordResult.accepted) {
      _hasAcceptedRequest = true;
      _status = ForgotPasswordStatus.genericSuccess;
    } else {
      _status = ForgotPasswordStatus.recoverableFailure;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
