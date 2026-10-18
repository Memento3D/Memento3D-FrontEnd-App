enum PaymentProvider { momo, zalopay, vnpay }

enum PaymentStatus { initial, processing, success, failed, cancelled }

/// Whole Vietnamese dong; no fractional or floating-point money.
class Money {
  const Money(this.vnd) : assert(vnd >= 0);
  final int vnd;
}

class CheckoutSummary {
  const CheckoutSummary({
    this.reference,
    this.items = const [],
    required this.subtotal,
    required this.serviceFee,
  });

  /// A demo reference only, never a backend order identifier.
  static const demo = CheckoutSummary(
    reference: 'M3D-2026-00125',
    subtotal: Money(249000),
    serviceFee: Money(0),
  );

  final String? reference;
  final List<CheckoutLine> items;
  final Money subtotal;
  final Money serviceFee;
  Money get total => Money(subtotal.vnd + serviceFee.vnd);
}

/// Immutable frontend checkout line, without backend product assumptions.
class CheckoutLine {
  const CheckoutLine({
    required this.name,
    this.description,
    required this.quantity,
    required this.unitPrice,
  });
  final String name;
  final String? description;
  final int quantity;
  final Money unitPrice;
}
