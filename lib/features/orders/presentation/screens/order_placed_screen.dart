import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../../data/services/order_service.dart';
import '../widgets/order_presentation.dart';
import 'order_detail_screen.dart';
import 'payment_gateway_screen.dart';

/// Step 2 of the ordering flow: the order exists on the server, so this screen
/// never offers a retry of the checkout itself — only the payment attempt.
class OrderPlacedScreen extends StatelessWidget {
  const OrderPlacedScreen({
    super.key,
    required this.order,
    this.payment,
    this.paymentError,
    this.service,
  });

  final Map<String, dynamic> order;
  final Map<String, dynamic>? payment;
  final String? paymentError;
  final OrderService? service;

  String get _orderId => order['id'] as String;

  bool get _paid {
    final status = order['paymentStatus']?.toString();
    return status == 'PAID' || status == 'SUCCESS';
  }

  @override
  Widget build(BuildContext context) {
    final paymentUrl =
        payment?['paymentUrl']?.toString() ?? payment?['deeplink']?.toString();
    final method =
        paymentMethodLabels[order['paymentMethod']?.toString()] ??
        order['paymentMethod']?.toString() ??
        '—';
    final orderCode = order['orderCode']?.toString() ?? _orderId;
    final title = _paid ? 'Thanh toán thành công' : 'Đặt hàng thành công';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: M3TopBar(
        title: title,
        showBack: false,
        showAvatar: false,
        leading: const Padding(
          padding: EdgeInsets.only(left: 10, right: 6),
          child: M3IconTile(Icons.check_rounded, size: 26, radius: 8),
        ),
        actions: [
          IconButton(
            tooltip: 'Đóng',
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          M3Card(
            radius: 24,
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.badgeGreenBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.badgeGreenText.withValues(alpha: 0.2),
                      width: 4,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 34,
                    color: AppColors.badgeGreenText,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _paid ? 'Giao dịch thành công!' : 'Đặt hàng thành công!',
                  style: m3Text(21, weight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  _paid
                      ? 'Đơn hàng chế tác kỷ vật 3D của bạn đã được thanh toán và chuyển sang xưởng in.'
                      : 'Chúng tôi đã nhận được đơn hàng của bạn',
                  textAlign: TextAlign.center,
                  style: m3Text(
                    12.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  formatVnd(order['totalPrice'] ?? order['totalAmount']),
                  style: m3Text(
                    22,
                    weight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                if (_paid)
                  M3Pill(
                    'Đã thanh toán qua $method',
                    icon: Icons.receipt_outlined,
                    background: AppColors.tint,
                  )
                else
                  OrderStatusBadge(status: order['status']),
                const Divider(height: 28, color: AppColors.cardBorder),
                Row(
                  children: [
                    const M3IconTile(Icons.view_in_ar_rounded, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['representativeProductName']?.toString() ??
                                'Kỷ vật điêu khắc lưu niệm',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: m3Text(13.5, weight: FontWeight.w700),
                          ),
                          Text(
                            '${order['itemCount'] ?? 1} sản phẩm · $method',
                            style: m3Text(11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OrderSectionCard(
            title: 'Chi tiết giao dịch',
            action: TextButton.icon(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: orderCode)),
              icon: const Icon(Icons.copy_rounded, size: 15),
              label: const Text('Sao chép mã'),
            ),
            child: Column(
              children: [
                OrderInfoRow(label: 'Mã đơn hàng', value: orderCode),
                OrderInfoRow(
                  label: 'Người nhận',
                  value: order['recipientName']?.toString() ?? '—',
                ),
                OrderInfoRow(
                  label: 'Số điện thoại',
                  value: order['phone']?.toString() ?? '—',
                ),
                OrderInfoRow(
                  label: 'Địa chỉ',
                  value: order['shippingAddress']?.toString() ?? '—',
                ),
                OrderInfoRow(label: 'Phương thức', value: method),
                const Divider(height: 20, color: AppColors.cardBorder),
                OrderInfoRow(
                  label: _paid ? 'Tổng tiền đã trả' : 'Tổng cộng',
                  value: formatVnd(order['totalPrice'] ?? order['totalAmount']),
                  emphasized: true,
                ),
              ],
            ),
          ),
          if (paymentError != null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.warningAmberBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warningAmberBorder),
              ),
              child: Text(
                '$paymentError Bạn có thể thanh toán lại từ trang chi tiết đơn hàng.',
                style: const TextStyle(color: AppColors.warningAmberText),
              ),
            ),
          if (!_paid && paymentUrl != null && paymentUrl.isNotEmpty)
            OrderSectionCard(
              title: 'Hoàn tất thanh toán',
              icon: Icons.qr_code_2_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Đơn hàng sẽ được xác nhận sau khi cổng thanh toán báo thành công.',
                    style: m3Text(13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  M3Button(
                    label: 'Mở trang thanh toán',
                    style: M3ButtonStyle.solid,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => PaymentGatewayScreen(
                          order: order,
                          payment: payment!,
                          service: service,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          OrderSectionCard(
            title: 'Tiến trình tiếp theo',
            action: OrderStatusBadge(status: order['status']),
            child: Builder(
              builder: (context) {
                final status = order['status']?.toString() ?? '';
                final reached = status == 'COMPLETED'
                    ? orderProgressSteps.length - 1
                    : orderProgressSteps.indexOf(status);
                return Column(
                  children: [
                    for (var i = 0; i < orderProgressSteps.length; i++)
                      _NextStep(
                        icon: i <= reached
                            ? Icons.check_rounded
                            : Icons.schedule_rounded,
                        title: orderStatusLabel(orderProgressSteps[i]),
                        body: i < reached
                            ? 'Đã hoàn thành'
                            : i == reached
                            ? 'Trạng thái hiện tại'
                            : 'Bước tiếp theo',
                        last: i == orderProgressSteps.length - 1,
                      ),
                  ],
                );
              },
            ),
          ),
          M3Button(
            label: 'Xem chi tiết đơn hàng',
            leading: Icons.receipt_long_outlined,
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) =>
                    OrderDetailScreen(orderId: _orderId, service: service),
              ),
            ),
          ),
          const SizedBox(height: 10),
          M3Button(
            label: 'Về trang chủ',
            style: M3ButtonStyle.outline,
            leading: Icons.home_outlined,
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
        ],
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({
    required this.icon,
    required this.title,
    required this.body,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Column(
          children: [
            M3IconTile(icon, size: 26, radius: 13),
            if (!last)
              Expanded(child: Container(width: 2, color: AppColors.tint)),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: last ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: m3Text(13, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: m3Text(
                    11.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
