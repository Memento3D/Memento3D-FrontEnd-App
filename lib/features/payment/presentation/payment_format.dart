import '../domain/payment.dart';

String providerName(PaymentProvider provider) => switch (provider) {
  PaymentProvider.momo => 'MoMo',
  PaymentProvider.zalopay => 'ZaloPay',
  PaymentProvider.vnpay => 'VNPAY',
};

String formatPaymentMoney(Money money, String locale) {
  final separator = locale.startsWith('vi') ? '.' : ',';
  final digits = money.vnd.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (match) => '${match[1]}$separator',
  );
  return '$digits ₫';
}
