import 'payment.dart';

abstract interface class PaymentRepository {
  /// Phase 1 simulation only. Returns a terminal outcome.
  Future<PaymentStatus> pay(CheckoutSummary summary, PaymentProvider provider);
}
