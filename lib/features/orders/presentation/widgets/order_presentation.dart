import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Formats a backend money value (`250000.00`) as `250.000 ₫`.
String formatVnd(Object? amount) {
  final value = amount is num
      ? amount.toDouble()
      : double.tryParse(amount?.toString() ?? '');
  if (value == null) return '—';
  final digits = value.round().abs().toString();
  final grouped = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) grouped.write('.');
    grouped.write(digits[index]);
  }
  return '${value < 0 ? '-' : ''}$grouped ₫';
}

/// Order lifecycle labels, in the same order the backend enum declares them.
const orderStatusLabels = <String, String>{
  'PENDING': 'Chờ xác nhận',
  'PENDING_PAYMENT': 'Chờ thanh toán',
  'CONFIRMED': 'Đã xác nhận',
  'PROCESSING': 'Đang xử lý',
  'PRINTING': 'Đang in 3D',
  'READY': 'Chờ giao hàng',
  'SHIPPED': 'Đang giao',
  'DELIVERED': 'Đã giao',
  'COMPLETED': 'Hoàn tất',
  'CANCELLED': 'Đã hủy',
  'REFUNDED': 'Đã hoàn tiền',
};

/// Statuses a customer may still cancel from.
const cancellableOrderStatuses = {'PENDING', 'PENDING_PAYMENT', 'CONFIRMED'};

/// Happy-path progression shown as a timeline on the detail screen.
const orderProgressSteps = [
  'PENDING',
  'CONFIRMED',
  'PRINTING',
  'SHIPPED',
  'DELIVERED',
];

const paymentMethodLabels = <String, String>{
  'CASH': 'Thanh toán khi nhận hàng (COD)',
  'MOMO': 'Ví MoMo',
  'ZALOPAY': 'ZaloPay',
  'VNPAY': 'VNPay',
};

const paymentStatusLabels = <String, String>{
  'PENDING': 'Chờ thanh toán',
  'PROCESSING': 'Đang xử lý',
  'PAID': 'Đã thanh toán',
  'SUCCESS': 'Đã thanh toán',
  'FAILED': 'Thanh toán thất bại',
  'REFUNDED': 'Đã hoàn tiền',
  'CANCELLED': 'Đã hủy',
};

String orderStatusLabel(Object? status) {
  final key = status?.toString() ?? '';
  return orderStatusLabels[key] ?? (key.isEmpty ? 'Không rõ' : key);
}

({Color background, Color foreground}) orderStatusColors(Object? status) {
  switch (status?.toString()) {
    case 'COMPLETED':
    case 'DELIVERED':
      return (
        background: AppColors.badgeGreenBg,
        foreground: AppColors.badgeGreenText,
      );
    case 'CANCELLED':
    case 'REFUNDED':
      return (background: Color(0xFFFEE2E2), foreground: Color(0xFFB91C1C));
    case 'PENDING':
    case 'PENDING_PAYMENT':
      return (
        background: AppColors.badgeAmberBg,
        foreground: AppColors.badgeAmberText,
      );
    case 'SHIPPED':
    case 'READY':
      return (
        background: AppColors.badgeOrangeBg,
        foreground: AppColors.badgeOrangeText,
      );
    default:
      return (
        background: AppColors.badgePurpleBg,
        foreground: AppColors.badgePurpleText,
      );
  }
}

/// Status pill reused by the order list, detail header and success screen.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final Object? status;

  @override
  Widget build(BuildContext context) {
    final colors = orderStatusColors(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: colors.foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              orderStatusLabel(status),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: colors.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White rounded card matching the home/profile surfaces.
class OrderSectionCard extends StatelessWidget {
  const OrderSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.action,
    this.icon,
  });

  final String title;
  final Widget child;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    // Material rather than a decorated box: the sections host ListTiles, which
    // paint their background and ink on the nearest Material ancestor.
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: AppColors.primary),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    ),
  );
}

/// Label / value row used for totals and shipping details.
class OrderInfoRow extends StatelessWidget {
  const OrderInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasized ? 15 : 13,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
              color: emphasized
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: emphasized ? 17 : 13,
              fontWeight: FontWeight.w700,
              color: emphasized ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Formats one address record the way the checkout and detail screens show it.
String formatAddress(Map<String, dynamic> address) {
  final formatted = address['formattedAddress']?.toString();
  if (formatted != null && formatted.trim().isNotEmpty) return formatted;
  return [address['streetAddress'], address['ward'], address['province']]
      .where((part) => part != null && part.toString().trim().isNotEmpty)
      .join(', ');
}
