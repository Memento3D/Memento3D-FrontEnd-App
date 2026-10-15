import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../../../home/presentation/widgets/notification_bell.dart';
import '../../data/services/order_service.dart';
import '../widgets/order_presentation.dart';
import 'order_detail_screen.dart';

/// Step 3 of the ordering flow: order history with status filters.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    this.client,
    this.service,
    this.embedded = false,
    this.onProfile,
  });

  final ApiClient? client;
  final OrderService? service;

  /// True when shown as a tab of the main screen (brand header, no back).
  final bool embedded;
  final VoidCallback? onProfile;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _pageSize = 10;
  static const _filters = <String?>[
    null,
    'PENDING',
    'CONFIRMED',
    'PRINTING',
    'SHIPPED',
    'COMPLETED',
    'CANCELLED',
  ];

  late final OrderService _service =
      widget.service ?? OrderService(client: widget.client);

  final _orders = <Map<String, dynamic>>[];
  Map<String, int> _counts = const {};
  String? _status;
  String _query = '';
  int _page = 1;
  int _total = 0;
  bool _busy = true;
  String? _error;

  bool get _hasMore => _orders.length < _total;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final page = more ? _page + 1 : 1;
      final result = await _service.myOrders(
        status: _status,
        page: page,
        limit: _pageSize,
      );
      Map<String, int>? counts;
      if (!more) {
        try {
          counts = await _service.statusCounts();
        } catch (_) {
          // Counts only decorate the filter chips; a failure must not hide the
          // list that loaded fine.
        }
      }
      if (!mounted) return;
      setState(() {
        if (!more) _orders.clear();
        _orders.addAll(result.orders);
        _page = page;
        _total = result.total;
        if (counts != null) _counts = counts;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể tải danh sách đơn hàng.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _selectFilter(String? status) {
    if (_busy || status == _status) return;
    setState(() => _status = status);
    _load();
  }

  Future<void> _openDetail(Map<String, dynamic> order) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(
          orderId: order['id'] as String,
          service: _service,
        ),
      ),
    );
    if (mounted) await _load();
  }

  List<Map<String, dynamic>> get _visibleOrders {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _orders;
    return _orders
        .where(
          (order) =>
              '${order['orderCode'] ?? ''} ${order['representativeProductName'] ?? ''}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _visibleOrders;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.embedded
          ? null
          : const M3TopBar(title: 'Đơn hàng', showAvatar: false),
      body: Column(
        children: [
          if (widget.embedded)
            M3BrandHeader(
              showLogo: true,
              subtitle: 'Đơn Hàng',
              actions: [
                const NotificationBell(),
                const SizedBox(width: 10),
                M3Avatar(onTap: widget.onProfile),
              ],
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: orders.length + 1 + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) return _header();
                  final i = index - 1;
                  if (i == orders.length) {
                    return Center(
                      child: TextButton(
                        onPressed: _busy ? null : () => _load(more: true),
                        child: const Text('Xem thêm'),
                      ),
                    );
                  }
                  return _OrderCard(
                    order: orders[i],
                    onTap: () => _openDetail(orders[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Đơn hàng của tôi', style: m3Text(22, weight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(
        'Theo dõi tiến độ chế tác & giao nhận kỷ vật',
        style: m3Text(12.5, color: AppColors.textSecondary),
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              style: m3Text(13.5),
              decoration: InputDecoration(
                hintText: 'Tìm mã đơn, tên kỷ vật...',
                hintStyle: m3Text(13.5, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.cardBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final filter in _filters)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: M3FilterChip(
                  selected: _status == filter,
                  onTap: () => _selectFilter(filter),
                  label: filter == null ? 'Tất cả' : orderStatusLabel(filter),
                  count: _filterCount(filter),
                  dotColor: filter == null
                      ? null
                      : orderStatusColors(filter).foreground,
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (_busy) const LinearProgressIndicator(minHeight: 2),
      if (_error != null)
        M3Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(child: Text(_error!, style: m3Text(13))),
              TextButton(
                onPressed: _busy ? null : _load,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      if (_orders.isEmpty && !_busy && _error == null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: Text(
              'Bạn chưa có đơn hàng nào.',
              style: m3Text(13.5, color: AppColors.textSecondary),
            ),
          ),
        ),
    ],
  );

  int? _filterCount(String? status) {
    final count = status == null
        ? (_counts['ALL'] ?? _counts['TOTAL'])
        : _counts[status];
    return count == null || count == 0 ? null : count;
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  static IconData _statusIcon(String? status) => switch (status) {
    'SHIPPED' || 'READY' => Icons.local_shipping_outlined,
    'COMPLETED' || 'DELIVERED' => Icons.check_circle_outline_rounded,
    'PENDING' || 'PENDING_PAYMENT' => Icons.assignment_outlined,
    'CANCELLED' || 'REFUNDED' => Icons.cancel_outlined,
    _ => Icons.view_in_ar_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString();
    final colors = orderStatusColors(status);
    final itemCount = (order['itemCount'] as num?)?.toInt() ?? 0;
    final thumbnail = order['representativeThumbnailUrl']?.toString();
    final paymentStatus = order['paymentStatus']?.toString();
    final paid = paymentStatus == 'PAID' || paymentStatus == 'SUCCESS';
    final secondaryLabel = switch (status) {
      'PRINTING' || 'PROCESSING' => 'Tiến độ 3D',
      'SHIPPED' || 'READY' => 'Lộ trình giao',
      'COMPLETED' || 'DELIVERED' => 'Đặt in lại',
      _ => null,
    };
    return M3Card(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_statusIcon(status), size: 18, color: colors.foreground),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order['orderCode']?.toString() ?? '',
                  style: m3Text(12.5, weight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: OrderStatusBadge(status: status)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 64,
                  height: 64,
                  color: AppColors.tint,
                  child: thumbnail == null || thumbnail.isEmpty
                      ? const Icon(
                          Icons.view_in_ar_outlined,
                          color: AppColors.primaryLight,
                        )
                      : Image.network(
                          thumbnail,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.view_in_ar_outlined,
                            color: AppColors.primaryLight,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order['representativeProductName']?.toString() ??
                          'Đơn chế tác',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: m3Text(15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      itemCount > 0 ? '$itemCount sản phẩm' : 'Đơn chế tác',
                      style: m3Text(12, color: AppColors.textSecondary),
                    ),
                    if (order['trackingCode'] != null) ...[
                      const SizedBox(height: 6),
                      M3Pill(
                        'Mã vận đơn: ${order['trackingCode']}',
                        icon: Icons.qr_code_2_rounded,
                        color: AppColors.textSecondary,
                        background: AppColors.tint,
                        fontSize: 10.5,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      paid ? 'Đã thanh toán' : 'Tổng chi phí',
                      style: m3Text(11.5, color: AppColors.textSecondary),
                    ),
                    Text(
                      formatVnd(order['totalPrice'] ?? order['totalAmount']),
                      style: m3Text(17, weight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              _ActionChip(label: 'Chi tiết đơn', onTap: onTap),
              if (secondaryLabel != null) ...[
                const SizedBox(width: 8),
                _ActionChip(label: secondaryLabel, onTap: onTap, strong: true),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.strong = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool strong;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: strong ? AppColors.primaryLight : AppColors.tint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: m3Text(
          12,
          weight: FontWeight.w700,
          color: strong ? Colors.white : AppColors.primary,
        ),
      ),
    ),
  );
}
