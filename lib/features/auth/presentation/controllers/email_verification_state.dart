import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/email_verification_result.dart';

enum EmailVerificationStatus {
  waiting,
  rateLimited,
  verifying,
  success,
  invalidOrExpired,
}

enum EmailVerificationFeedback { resendSent, resendFailed, verificationFailed }

class EmailVerificationState extends ChangeNotifier {
  EmailVerificationState({
    required this.service,
    this.email,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final EmailVerificationService service;
  final String? email;
  final DateTime Function() _now;
  EmailVerificationStatus _phase = EmailVerificationStatus.waiting;
  EmailVerificationFeedback? _feedback;
  DateTime? _retryAt;
  Timer? _ticker;
  String? _retryToken;
  bool _resending = false;
  bool _disposed = false;
  int _revision = 0;

  EmailVerificationStatus get phase => _phase;
  EmailVerificationFeedback? get feedback => _feedback;
  DateTime? get retryAt => _retryAt;
  bool get isResending => _resending;
  bool get hasEmail => email?.trim().isNotEmpty ?? false;

  int get remainingSeconds {
    final deadline = _retryAt;
    if (deadline == null) return 0;
    final milliseconds = deadline.difference(_now()).inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  /// Rate limiting overlays resend eligibility, preserving the underlying phase.
  EmailVerificationStatus get status =>
      (_phase == EmailVerificationStatus.waiting ||
              _phase == EmailVerificationStatus.invalidOrExpired) &&
          remainingSeconds > 0
      ? EmailVerificationStatus.rateLimited
      : _phase;

  bool get canResend =>
      !_disposed &&
      hasEmail &&
      !_resending &&
      remainingSeconds == 0 &&
      (_phase == EmailVerificationStatus.waiting ||
          _phase == EmailVerificationStatus.invalidOrExpired);

  bool get canRetryVerification =>
      !_disposed &&
      _feedback == EmailVerificationFeedback.verificationFailed &&
      _retryToken != null &&
      _phase != EmailVerificationStatus.verifying;

  Future<void> resend() async {
    if (!canResend) return;
    final revision = _revision;
    _resending = true;
    _feedback = null;
    notifyListeners();
    try {
      final result = await service.resend(email!.trim());
      if (_disposed) return;
      _retryAt = result.retryAt;
      // An incoming token may have superseded the resend request.
      if (revision == _revision) {
        if (result.retryAt == null) {
          _phase = EmailVerificationStatus.waiting;
          _feedback = EmailVerificationFeedback.resendSent;
        }
      }
      _startCountdown();
    } catch (_) {
      if (_disposed) return;
      if (revision == _revision) {
        _feedback = EmailVerificationFeedback.resendFailed;
      }
    } finally {
      if (!_disposed) {
        _resending = false;
        notifyListeners();
      }
    }
  }

  Future<void> verifyToken(String token) async {
    if (_disposed ||
        _phase == EmailVerificationStatus.verifying ||
        _phase == EmailVerificationStatus.success) {
      return;
    }
    if (token.trim().isEmpty) return;
    final previousPhase = _phase;
    _revision++;
    _retryToken = token;
    _phase = EmailVerificationStatus.verifying;
    _feedback = null;
    notifyListeners();
    try {
      final result = await service.verifyToken(token);
      if (_disposed) return;
      _phase = result == EmailVerificationResult.success
          ? EmailVerificationStatus.success
          : EmailVerificationStatus.invalidOrExpired;
      _retryToken = null;
      if (_phase == EmailVerificationStatus.success) {
        _ticker?.cancel();
        _retryAt = null;
      }
    } catch (_) {
      if (_disposed) return;
      _phase = previousPhase;
      _feedback = EmailVerificationFeedback.verificationFailed;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> retryVerification() async {
    if (canRetryVerification) await verifyToken(_retryToken!);
  }

  void _startCountdown() {
    _ticker?.cancel();
    if (_phase == EmailVerificationStatus.success) {
      _retryAt = null;
      return;
    }
    if (remainingSeconds > 0) {
      _ticker = Timer.periodic(
        const Duration(seconds: 1),
        (_) => refreshTime(),
      );
    } else {
      _retryAt = null;
    }
  }

  /// Recalculate on resume as well as ticks; the deadline is the source of truth.
  void refreshTime() {
    if (_disposed) return;
    if (remainingSeconds == 0) {
      _ticker?.cancel();
      _retryAt = null;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _retryToken = null;
    super.dispose();
  }
}
