import 'package:flutter/material.dart';

import 'dart:async';

import '../../../customization/presentation/frozen_order_design_panel.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/services/order_service.dart';
import '../widgets/order_presentation.dart';
import 'payment_webview_screen.dart';

/// Step 4 of the ordering flow: order detail, production timeline, payment
/// retry and cancellation.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.orderId,
    this.client,
    this.service,
  });

  final String orderId;
  final ApiClient? client;
  final OrderService? service;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with WidgetsBindingObserver {
  late final OrderService _service =
      widget.service ?? OrderService(client: widget.client);

  Map<String, dynamic>? _order;
  bool _busy = true;
  String? _error;
  Timer? _pollTimer;
  bool _loadingOrder = false, _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  String _message(Object error, String fallback) =>
      error is ApiException ? error.message : fallback;

  Future<void> _load() async {
    if (_loadingOrder) return;
    _loadingOrder = true;
    _pollTimer?.cancel();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await _service.orderDetail(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(
            error,
            'Không thể tải chi tiết đơn hàng. Vui lòng thử lại.',
          ),
        );
      }
    } finally {
      _loadingOrder = false;
      if (mounted) setState(() => _busy = false);
      if (mounted &&
          !_paused &&
          _order != null &&
          isCustomPrintOrder(_order!) &&
          ![
            'CANCELLED',
            'COMPLETED',
            'DELIVERED',
            'REFUNDED',
          ].contains(_order!['status'])) {
        _pollTimer = Timer(const Duration(seconds: 8), _load);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _pollTimer?.cancel();
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _acceptQuote() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.acceptWorkshopQuote(widget.orderId);
      await _load();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(error, 'Chưa chấp thuận được báo giá.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy đơn hàng?'),
        content: const Text(
          'Đơn hàng sẽ được hủy và không thể hoàn tác. Khoản đã thanh toán sẽ được xử lý hoàn tiền theo chính sách.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ đơn'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đơn'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final order = await _service.cancelOrder(widget.orderId);
      if (mounted) setState(() => _order = order);
    } catch (error) {
      if (mounted) {
        setState(() => _error = _message(error, 'Không thể hủy đơn hàng này.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payAgain() async {
    final method = _order!=null&&isCustomPrintOrder(_order!)?'VNPAY':_order?['paymentMethod']?.toString() ?? 'MOMO';
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final payment = await _service.initiatePayment(
        orderId: widget.orderId,
        paymentMethod: method == 'CASH' ? 'MOMO' : method,
      );
      final url =
          payment['paymentUrl']?.toString() ?? payment['deeplink']?.toString();
      if (!mounted) return;
      if (url == null || url.isEmpty) {
        setState(() => _error = 'Cổng thanh toán chưa trả về liên kết.');
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => PaymentWebViewScreen(url: url,returnUri:method=='VNPAY'?Uri.parse(ApiConfig.baseUrl).resolve('/api/v1/payments/vnpay/return'):null)),
      );
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(error, 'Không thể khởi tạo thanh toán.'),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final status = order?['status']?.toString();
    final paymentStatus = order?['paymentStatus']?.toString();
    final canCancel =
        order != null && cancellableOrderStatuses.contains(status) && !_busy;
    final canPay =
        order != null &&
        !_busy &&
        order['paymentMethod']?.toString() != 'CASH' &&
        (paymentStatus == 'PENDING' || paymentStatus == 'FAILED') &&
        status != 'CANCELLED' &&
        status != 'REFUNDED';
    final custom = order != null && isCustomPrintOrder(order);
    final customCanPay =
        !custom ||
        (order['feasibilityStatus'] == 'ACCEPTED' &&
            ((order['totalAmount'] ?? order['totalPrice']) as num? ?? 0) > 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: M3TopBar(
        title: 'Chi tiết đơn hàng',
        subtitle: order?['orderCode']?.toString(),
      ),
      body: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          if (_error != null)
            ListTile(
              title: Text(_error!),
              trailing: TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('Thử lại'),
              ),
            ),
          Expanded(
            child: order == null
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _statusSection(order),
                        if (custom)
                          FrozenOrderDesignPanel(
                            key: ValueKey(widget.orderId),
                            orderId: widget.orderId,
                            client: widget.client,
                          ),
                        if (custom &&
                            order['feasibilityStatus'] == 'PENDING_REVIEW')
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Đang chờ xưởng kiểm tra và báo giá. Chưa đến bước thanh toán.',
                            ),
                          ),
                        if (custom && order['feasibilityStatus'] == 'FEASIBLE')
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Báo giá từ xưởng: ${formatVnd(order['totalAmount'] ?? order['totalPrice'])}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Dự kiến ${order['estimatedProductionDays'] ?? '—'} ngày. ${order['feasibilityNotes'] ?? ''}',
                                  ),
                                  FilledButton(
                                    onPressed: _busy ? null : _acceptQuote,
                                    child: const Text('Đồng ý báo giá'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        _itemsSection(order['items'] as List? ?? const []),
                        _shippingSection(order),
                        _paymentSection(order),
                        _totalsSection(order),
                      ],
                    ),
                  ),
          ),
          if ((canPay && customCanPay) || canCancel)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (canCancel)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _cancel,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.cardBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Hủy đơn hàng'),
                        ),
                      ),
                    if (canCancel && canPay && customCanPay)
                      const SizedBox(width: 12),
                    if (canPay && customCanPay)
                      Expanded(
                        child: FilledButton(
                          onPressed: _payAgain,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Thanh toán'),
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

  Widget _statusSection(Map<String, dynamic> order) {
    final status = order['status']?.toString();
    final cancelled = status == 'CANCELLED' || status == 'REFUNDED';
    final current = orderProgressSteps.indexOf(status ?? '');
    final reached = status == 'COMPLETED'
        ? orderProgressSteps.length - 1
        : current;
    return OrderSectionCard(
      title: 'Trạng thái đơn hàng',
      action: OrderStatusBadge(status: status),
      child: cancelled
          ? Text(
              'Đơn hàng ${orderStatusLabel(status).toLowerCase()}.',
              style: const TextStyle(color: AppColors.textSecondary),
            )
          : Column(
              children: [
                for (var index = 0; index < orderProgressSteps.length; index++)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: index <= reached
                                  ? AppColors.primary
                                  : AppColors.tint,
                              shape: BoxShape.circle,
                            ),
                            child: index <= reached
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  )
                                : Center(
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: AppColors.tintStrong,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                          ),
                          if (index < orderProgressSteps.length - 1)
                            Container(
                              width: 2,
                              height: 20,
                              color: index < reached
                                  ? AppColors.primary
                                  : AppColors.tint,
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1, bottom: 12),
                          child: Text(
                            orderStatusLabel(orderProgressSteps[index]),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: index == reached
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: index <= reached
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _itemsSection(List<dynamic> items) => OrderSectionCard(
    title: 'Sản phẩm',
    child: items.isEmpty
        ? const Text(
            'Đơn chế tác theo phiên scan, chưa có danh sách sản phẩm.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        : Column(
            children: [
              for (final raw in items)
                if (raw is Map)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                raw['productName']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              formatVnd(raw['subtotal']),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            '${formatVnd(raw['unitPrice'])} × ${raw['quantity'] ?? 1}',
                            if (raw['material'] != null) raw['material'],
                            if (raw['dimensions'] != null) raw['dimensions'],
                            if (raw['finish'] != null) raw['finish'],
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (raw['personalization'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Khắc tên: ${raw['personalization']}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.badgePurpleText,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            ],
          ),
  );

  Widget _shippingSection(Map<String, dynamic> order) => OrderSectionCard(
    title: 'Giao hàng',
    icon: Icons.local_shipping_outlined,
    child: Column(
      children: [
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
        if (order['shippingCarrier'] != null)
          OrderInfoRow(
            label: 'Đơn vị vận chuyển',
            value: order['shippingCarrier'].toString(),
          ),
        if (order['trackingCode'] != null)
          OrderInfoRow(
            label: 'Mã vận đơn',
            value: order['trackingCode'].toString(),
          ),
        if (order['note'] != null && order['note'].toString().isNotEmpty)
          OrderInfoRow(label: 'Ghi chú', value: order['note'].toString()),
      ],
    ),
  );

  Widget _paymentSection(Map<String, dynamic> order) => OrderSectionCard(
    title: 'Thanh toán',
    icon: Icons.account_balance_wallet_outlined,
    child: Column(
      children: [
        OrderInfoRow(
          label: 'Phương thức',
          value:
              paymentMethodLabels[order['paymentMethod']?.toString()] ??
              order['paymentMethod']?.toString() ??
              '—',
        ),
        OrderInfoRow(
          label: 'Tình trạng',
          value:
              paymentStatusLabels[order['paymentStatus']?.toString()] ??
              order['paymentStatus']?.toString() ??
              '—',
        ),
        OrderInfoRow(
          label: 'Đã thanh toán',
          value: formatVnd(order['paidAmount']),
        ),
        OrderInfoRow(
          label: 'Còn lại',
          value: formatVnd(order['remainingAmount']),
        ),
      ],
    ),
  );

  Widget _totalsSection(Map<String, dynamic> order) => OrderSectionCard(
    title: 'Chi tiết giá',
    icon: Icons.receipt_long_outlined,
    child: Column(
      children: [
        OrderInfoRow(label: 'Tạm tính', value: formatVnd(order['subtotal'])),
        OrderInfoRow(
          label: 'Giảm giá',
          value: formatVnd(order['discountAmount']),
        ),
        OrderInfoRow(
          label: 'Phí giao hàng',
          value: formatVnd(order['shippingFee']),
        ),
        if (order['customizationFee'] != null)
          OrderInfoRow(
            label: 'Phí cá nhân hóa',
            value: formatVnd(order['customizationFee']),
          ),
        if (order['productionSurcharge'] != null)
          OrderInfoRow(
            label: 'Phụ phí sản xuất',
            value: formatVnd(order['productionSurcharge']),
          ),
        const Divider(height: 20, color: AppColors.cardBorder),
        OrderInfoRow(
          label: 'Tổng cộng',
          value: formatVnd(order['totalPrice'] ?? order['totalAmount']),
          emphasized: true,
        ),
      ],
    ),
  );
}
