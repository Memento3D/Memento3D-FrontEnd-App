import 'package:flutter/foundation.dart';

import '../../domain/payment.dart';
import '../../domain/payment_repository.dart';

class PaymentController extends ChangeNotifier {
  PaymentController({
    required this.repository,
    this.summary = CheckoutSummary.demo,
  });

  final PaymentRepository repository;
  final CheckoutSummary summary;
  PaymentProvider _provider = PaymentProvider.momo;
  PaymentStatus _status = PaymentStatus.initial;
  bool _disposed = false;
  int _generation = 0;

  PaymentProvider get provider => _provider;
  PaymentStatus get status => _status;

  void selectProvider(PaymentProvider provider) {
    if (_disposed ||
        _status != PaymentStatus.initial ||
        provider == _provider) {
      return;
    }
    _provider = provider;
    notifyListeners();
  }

  Future<void> start() async {
    if (_disposed ||
        !{PaymentStatus.initial, PaymentStatus.failed}.contains(_status)) {
      return;
    }
    final generation = ++_generation;
    _status = PaymentStatus.processing;
    notifyListeners();
    PaymentStatus result;
    try {
      result = await repository.pay(summary, _provider);
      if (!{
        PaymentStatus.success,
        PaymentStatus.failed,
        PaymentStatus.cancelled,
      }.contains(result)) {
        result = PaymentStatus.failed;
      }
    } catch (_) {
      result = PaymentStatus.failed;
    }
    if (_disposed || generation != _generation) return;
    _status = result;
    notifyListeners();
  }

  void reset() {
    if (_disposed || _status == PaymentStatus.processing) return;
    ++_generation;
    _status = PaymentStatus.initial;
    notifyListeners();
  }

  /// Cancels the local simulation and ignores any late completion.
  void cancel() {
    if (_disposed || _status != PaymentStatus.processing) return;
    ++_generation;
    _status = PaymentStatus.cancelled;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    super.dispose();
  }
}
