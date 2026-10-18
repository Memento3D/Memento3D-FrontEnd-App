import '../domain/payment.dart';
import '../domain/payment_repository.dart';

/// No transport or provider integration. Inject zero delay in tests.
class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository({
    this.outcome = PaymentStatus.success,
    this.delay = const Duration(milliseconds: 1200),
  }) {
    if (!const {
      PaymentStatus.success,
      PaymentStatus.failed,
      PaymentStatus.cancelled,
    }.contains(outcome)) {
      throw ArgumentError.value(outcome, 'outcome', 'Must be terminal');
    }
  }

  final PaymentStatus outcome;
  final Duration delay;

  @override
  Future<PaymentStatus> pay(
    CheckoutSummary summary,
    PaymentProvider provider,
  ) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return outcome;
  }
}
