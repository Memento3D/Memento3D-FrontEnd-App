import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../widgets/order_presentation.dart';
import 'checkout_screen.dart';

/// "Giỏ hàng": cart items with quantity steppers and a payment summary.
class CartScreen extends StatefulWidget {
  const CartScreen({
    super.key,
    this.client,
    this.embedded = false,
    this.onProfile,
  });

  final ApiClient? client;

  /// True when shown as a tab of the main screen (brand header, no back).
  final bool embedded;
  final VoidCallback? onProfile;

  @override
  State<CartScreen> createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  late final ApiClient _client = widget.client ?? ApiClient();
  Map<String, dynamic>? _cart;
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await _client.get('/api/v1/cart');
      if (response is! Map || response['items'] is! List) {
        throw const FormatException('Invalid cart');
      }
      if (mounted) setState(() => _cart = Map<String, dynamic>.from(response));
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể tải giỏ hàng.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) await reload();
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is ApiException
              ? error.message
              : 'Không thể cập nhật giỏ hàng.';
          _busy = false;
        });
      }
    }
  }

  Future<void> _change(Map item, int quantity) {
    final id = Uri.encodeComponent(item['id'].toString());
    return _mutate(() async {
      if (quantity <= 0) {
        await _client.delete('/api/v1/cart/items/$id');
      } else {
        await _client.patch(
          '/api/v1/cart/items/$id',
          body: {'quantity': quantity},
        );
      }
    });
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa tất cả sản phẩm?'),
        content: const Text('Giỏ hàng sẽ được làm trống.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _mutate(() => _client.delete('/api/v1/cart'));
  }

  Future<void> _checkout() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => CheckoutScreen(client: _client)),
    );
    // The cart is emptied server-side on a successful checkout, so re-read it
    // instead of trusting the snapshot shown before leaving.
    if (mounted) await reload();
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart?['items'] as List? ?? [];
    final discount = num.tryParse('${_cart?['discount'] ?? 0}') ?? 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.embedded
          ? null
          : const M3TopBar(title: 'Giỏ hàng', showAvatar: false),
      body: Column(
        children: [
          if (widget.embedded)
            M3BrandHeader(
              actions: [
                const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 12),
                M3Avatar(onTap: widget.onProfile),
              ],
            ),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(
                    children: [
                      Text(
                        'Giỏ hàng',
                        style: m3Text(21, weight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      M3Pill(
                        '${items.length} sản phẩm',
                        background: AppColors.tint,
                      ),
                      const Spacer(),
                      if (items.isNotEmpty)
                        TextButton.icon(
                          onPressed: _busy ? null : _clear,
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 18,
                          ),
                          label: const Text('Xóa tất cả'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_error != null)
                    M3Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(_error!, style: m3Text(13))),
                          TextButton(
                            onPressed: _busy ? null : reload,
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    ),
                  if (items.isEmpty && !_busy && _error == null)
                    _empty()
                  else
                    for (final raw in items) _itemCard(raw as Map),
                  if (_cart != null && items.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    M3Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chi tiết thanh toán',
                            style: m3Text(14, weight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          M3KeyValue(
                            'Tạm tính (${items.length} món)',
                            formatVnd(_cart!['subtotal']),
                          ),
                          if (discount != 0)
                            M3KeyValue(
                              'Giảm giá voucher',
                              '-${formatVnd(discount.abs())}',
                              valueColor: AppColors.badgeGreenText,
                            ),
                          M3KeyValue(
                            'Phí giao hàng',
                            num.tryParse('${_cart!['shippingFee'] ?? 0}') == 0
                                ? 'Miễn phí'
                                : formatVnd(_cart!['shippingFee']),
                            valueColor:
                                num.tryParse('${_cart!['shippingFee'] ?? 0}') ==
                                    0
                                ? AppColors.badgeGreenText
                                : AppColors.textPrimary,
                          ),
                          const Divider(
                            height: 18,
                            color: AppColors.cardBorder,
                          ),
                          M3KeyValue(
                            'Tổng thanh toán',
                            formatVnd(_cart!['total']),
                            bold: true,
                            valueColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    M3Button(
                      label:
                          'Tiến hành đặt hàng (${formatVnd(_cart!['total'])})',
                      style: M3ButtonStyle.solid,
                      trailing: Icons.arrow_forward_rounded,
                      onPressed: _busy ? null : _checkout,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Column(
      children: [
        const M3IconTile(Icons.shopping_cart_outlined, size: 64, radius: 32),
        const SizedBox(height: 14),
        Text(
          'Giỏ hàng đang trống.',
          style: m3Text(15, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Thêm kỷ vật 3D để đặt in và giao tận nơi.',
          textAlign: TextAlign.center,
          style: m3Text(12.5, color: AppColors.textSecondary),
        ),
      ],
    ),
  );

  Widget _itemCard(Map item) {
    final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
    final thumbnail = item['thumbnailUrl']?.toString();
    final customization = item['customization'];
    final details = <String>[
      if (item['categoryName'] != null) item['categoryName'].toString(),
      if (customization is Map)
        ...customization.entries
            .where((e) => e.value != null && '${e.value}'.isNotEmpty)
            .take(2)
            .map((e) => '${e.value}'),
    ];
    return M3Card(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              height: 72,
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['productName']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: m3Text(14, weight: FontWeight.w700),
                      ),
                    ),
                    GestureDetector(
                      onTap: _busy ? null : () => _change(item, 0),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                for (final detail in details)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $detail',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: m3Text(11.5, color: AppColors.textSecondary),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatVnd(item['subtotal'] ?? item['unitPrice']),
                        style: m3Text(
                          15,
                          weight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _stepButton(
                            Icons.remove_rounded,
                            quantity == 1 ? 'Xóa' : 'Giảm số lượng',
                            () => _change(item, quantity - 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '$quantity',
                              style: m3Text(13, weight: FontWeight.w700),
                            ),
                          ),
                          _stepButton(
                            Icons.add_rounded,
                            'Tăng số lượng',
                            () => _change(item, quantity + 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepButton(IconData icon, String tooltip, VoidCallback onTap) =>
      IconButton(
        tooltip: tooltip,
        onPressed: _busy ? null : onTap,
        icon: Icon(icon, size: 16),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      );
}
