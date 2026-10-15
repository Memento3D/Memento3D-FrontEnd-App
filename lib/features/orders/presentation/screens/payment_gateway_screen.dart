import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../../data/services/order_service.dart';
import '../widgets/order_presentation.dart';
import 'order_placed_screen.dart';
import 'payment_webview_screen.dart';

/// "Thanh toán MoMo": QR + deeplink for an e-wallet payment the backend has
/// already initiated. Confirmation still comes from the gateway callback, so
/// "Tôi đã thanh toán" re-reads the order instead of assuming success.
class PaymentGatewayScreen extends StatefulWidget {
  const PaymentGatewayScreen({
    super.key,
    required this.order,
    required this.payment,
    this.service,
  });

  final Map<String, dynamic> order;
  final Map<String, dynamic> payment;
  final OrderService? service;

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  late final OrderService _service = widget.service ?? OrderService();

  /// Only shown when the gateway returns an expiry; never guessed.
  late final DateTime? _expiresAt = DateTime.tryParse(
    widget.payment['expiresAt']?.toString() ?? '',
  )?.toLocal();
  Timer? _ticker;
  Duration _left = Duration.zero;
  bool _checking = false;

  bool get _isMomo =>
      (widget.payment['paymentMethod'] ?? widget.order['paymentMethod'])
          ?.toString() ==
      'MOMO';

  String get _brand => _isMomo
      ? 'MoMo'
      : paymentMethodLabels[widget.order['paymentMethod']?.toString()] ??
            'Ví điện tử';

  Color get _brandColor => _isMomo ? AppColors.momo : AppColors.primary;

  @override
  void initState() {
    super.initState();
    if (_expiresAt == null) return;
    _tick();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final left = _expiresAt!.difference(DateTime.now());
    setState(() => _left = left.isNegative ? Duration.zero : left);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _clock {
    final m = _left.inMinutes.toString().padLeft(2, '0');
    final s = (_left.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _openGateway() {
    final url =
        widget.payment['deeplink']?.toString() ??
        widget.payment['paymentUrl']?.toString();
    if (url == null || url.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PaymentWebViewScreen(url: url)),
    );
  }

  Future<void> _confirmPaid() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final order = await _service.orderDetail(widget.order['id'] as String);
      if (!mounted) return;
      final status = order['paymentStatus']?.toString();
      if (status == 'PAID' || status == 'SUCCESS') {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => OrderPlacedScreen(order: order, service: _service),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa nhận được xác nhận thanh toán. Vui lòng thử lại sau ít phút.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'Không thể kiểm tra trạng thái thanh toán.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrData =
        widget.payment['qrCodeUrl']?.toString() ??
        widget.payment['paymentUrl']?.toString();
    final hasGateway =
        (widget.payment['deeplink'] ?? widget.payment['paymentUrl']) != null;
    final orderCode =
        widget.order['orderCode']?.toString() ?? widget.order['id'].toString();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: M3TopBar(title: 'Thanh toán $_brand'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          LinearProgressIndicator(
            value: 1,
            minHeight: 3,
            color: AppColors.primary,
            backgroundColor: AppColors.tint,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              M3Pill(
                'Bước 3/3',
                color: _brandColor,
                background: _brandColor.withValues(alpha: 0.08),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Xác thực thanh toán QR',
                  style: m3Text(12, color: AppColors.textSecondary),
                ),
              ),
              if (_expiresAt != null)
                M3Pill(
                  _clock,
                  icon: Icons.timer_outlined,
                  color: AppColors.textPrimary,
                  background: Colors.white,
                ),
            ],
          ),
          const SizedBox(height: 14),
          M3Card(
            radius: 24,
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _brandColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isMomo ? 'MoMo' : _brand.characters.first,
                        style: m3Text(
                          13,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isMomo ? 'Ví Điện Tử MoMo' : _brand,
                            style: m3Text(16, weight: FontWeight.w800),
                          ),
                          Text(
                            'Cổng thanh toán tự động',
                            style: m3Text(11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.tint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Tổng số tiền cần thanh toán',
                        style: m3Text(12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatVnd(
                          widget.payment['amount'] ??
                              widget.order['totalPrice'],
                        ),
                        style: m3Text(
                          22,
                          weight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (qrData != null && qrData.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _brandColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: QrImageView(
                      data: qrData,
                      size: 170,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: _brandColor,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1F1B2D),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Quét mã để hoàn tất thanh toán',
                  style: m3Text(14, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mở ứng dụng $_brand hoặc camera điện thoại hỗ trợ QR',
                  textAlign: TextAlign.center,
                  style: m3Text(12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.tint.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      M3KeyValue(
                        'Mã đơn hàng',
                        orderCode,
                        valueWidget: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              child: Text(
                                orderCode,
                                overflow: TextOverflow.ellipsis,
                                style: m3Text(12.5, weight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => Clipboard.setData(
                                ClipboardData(text: orderCode),
                              ),
                              child: const Icon(
                                Icons.copy_rounded,
                                size: 15,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      M3KeyValue(
                        'Dịch vụ',
                        widget.order['representativeProductName']?.toString() ??
                            'Chế tác kỷ vật 3D',
                      ),
                      if (_expiresAt != null)
                        M3KeyValue(
                          'Thời gian giữ chỗ',
                          _left == Duration.zero
                              ? 'Đã hết hạn'
                              : 'Hết hạn sau $_clock',
                          valueColor: AppColors.error,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          M3Button(
            label: 'Mở ứng dụng $_brand',
            style: _isMomo ? M3ButtonStyle.momo : M3ButtonStyle.solid,
            leading: Icons.open_in_new_rounded,
            onPressed: hasGateway ? _openGateway : null,
          ),
          const SizedBox(height: 10),
          M3Button(
            label: 'Tôi đã thanh toán',
            style: M3ButtonStyle.outline,
            leading: Icons.check_circle_outline_rounded,
            loading: _checking,
            onPressed: _confirmPaid,
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Gặp sự cố thanh toán? Hỗ trợ 24/7',
              style: m3Text(
                12,
                color: AppColors.textSecondary,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}
