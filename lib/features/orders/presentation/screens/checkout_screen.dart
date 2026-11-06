import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../home/presentation/screens/addresses_screen.dart';
import '../../data/services/order_service.dart';
import '../widgets/order_presentation.dart';
import 'order_placed_screen.dart';
import 'payment_gateway_screen.dart';

/// Step 1 of the ordering flow: review the cart, pick a delivery address and a
/// payment method, then place the order.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    this.client,
    this.service,
    this.scanId,
    this.quote,
    this.bespokeTitle,
    this.bespokeSummary,
    this.bespokeNote,
  });

  final ApiClient? client;
  final OrderService? service;

  /// Set when checking out a bespoke scan instead of catalog products.
  final String? scanId;

  /// Locked server quote for a bespoke scan order. When present the cart is not
  /// involved: the order is priced from this quote alone.
  final Map<String, dynamic>? quote;
  final String? bespokeTitle;
  final String? bespokeSummary;

  /// Chosen size / material / engraving, sent to the workshop in the order note.
  final String? bespokeNote;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final OrderService _service =
      widget.service ?? OrderService(client: widget.client);
  final _note = TextEditingController();

  Map<String, dynamic>? _cart;
  List<Map<String, dynamic>> _addresses = [];
  String? _addressId;
  String _paymentMethod = 'CASH';
  bool _busy = true;
  bool _placing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  bool get _isBespoke => widget.quote != null;

  Object? get _total =>
      _isBespoke ? (widget.quote ?? const {})['totalAmount'] : _cart?['total'];

  String _message(Object error, String fallback) =>
      error is ApiException ? error.message : fallback;

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        if (_isBespoke)
          Future<Map<String, dynamic>>.value(<String, dynamic>{
            'items': const <dynamic>[],
          })
        else
          _service.loadCart(),
        _service.loadAddresses(),
      ]);
      final cart = results[0] as Map<String, dynamic>;
      final addresses = results[1] as List<Map<String, dynamic>>;
      final preferred = addresses.firstWhere(
        (address) => address['isDefault'] == true,
        orElse: () => addresses.isEmpty ? <String, dynamic>{} : addresses.first,
      );
      if (!mounted) return;
      setState(() {
        _cart = cart;
        _addresses = addresses;
        _addressId = preferred['id'] as String?;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(
            error,
            'Không thể tải thông tin đặt hàng. Vui lòng thử lại.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _manageAddresses() async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AddressesScreen()));
    if (mounted) await _load();
  }

  Map<String, dynamic>? get _address {
    final id = _addressId;
    if (id == null) return null;
    for (final address in _addresses) {
      if (address['id'] == id) return address;
    }
    return null;
  }

  Future<void> _placeOrder() async {
    final address = _address;
    final items = _cart?['items'] as List? ?? const [];
    if (_placing || address == null || (items.isEmpty && !_isBespoke)) return;
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final order = await _service.createOrder(
        recipientName: address['recipientName']?.toString() ?? '',
        shippingAddress: formatAddress(address),
        phone: address['phone']?.toString() ?? '',
        paymentMethod: _paymentMethod,
        note: [
          if (_isBespoke && (widget.bespokeNote ?? '').isNotEmpty)
            'Cấu hình: ${widget.bespokeNote}',
          _note.text.trim(),
        ].where((part) => part.isNotEmpty).join('\n'),
        scanId: widget.scanId,
        quoteId: widget.quote?['id'] as String?,
        totalPrice: widget.quote?['totalAmount'] as num?,
        idempotencyKey:
            'checkout-${address['id']}-${DateTime.now().millisecondsSinceEpoch}',
      );

      Map<String, dynamic>? payment;
      String? paymentError;
      if (_paymentMethod != 'CASH') {
        try {
          payment = await _service.initiatePayment(
            orderId: order['id'] as String,
            paymentMethod: _paymentMethod,
          );
        } catch (error) {
          paymentError = _message(
            error,
            'Đơn hàng đã được tạo nhưng chưa khởi tạo được thanh toán.',
          );
        }
      }

      if (!mounted) return;
      final hasGateway =
          payment != null &&
          (payment['qrCodeUrl'] ??
                  payment['paymentUrl'] ??
                  payment['deeplink']) !=
              null;
      if (hasGateway) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PaymentGatewayScreen(
              order: order,
              payment: payment!,
              service: _service,
            ),
          ),
        );
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderPlacedScreen(
            order: order,
            payment: payment,
            paymentError: paymentError,
            service: _service,
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(
            error,
            'Không thể đặt hàng. Vui lòng kiểm tra lại và thử lần nữa.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _cart?['items'] as List? ?? const [];
    final canPlace =
        !_placing &&
        !_busy &&
        (items.isNotEmpty || _isBespoke) &&
        _address != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const M3TopBar(title: 'Xác nhận đơn hàng'),
      body: Column(
        children: [
          if (_busy || _placing) const LinearProgressIndicator(),
          if (_error != null)
            Container(
              width: double.infinity,
              color: AppColors.warningAmberBg,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppColors.warningAmberText),
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _load,
                    child: const Text('Tải lại'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: items.isEmpty && !_busy && !_isBespoke
                ? const Center(
                    child: Text('Giỏ hàng đang trống, chưa thể đặt hàng.'),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _stepBanner(),
                      _addressSection(),
                      if (_isBespoke)
                        _bespokeSection()
                      else
                        _itemsSection(items),
                      _paymentSection(),
                      _noteSection(),
                      _summarySection(),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.cardBorder)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tổng thanh toán',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        formatVnd(_total),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: canPlace ? _placeOrder : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(150, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 19),
                  label: Text(_placing ? 'Đang đặt hàng…' : 'Đặt hàng'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepBanner() => Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.tint,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        const Icon(Icons.verified_outlined, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Bước cuối: Kiểm tra thông số & xác nhận in 3D',
            style: m3Text(12, weight: FontWeight.w600),
          ),
        ),
        Text(
          '3/3',
          style: m3Text(12, weight: FontWeight.w700, color: AppColors.primary),
        ),
      ],
    ),
  );

  Widget _selectTile({
    required bool selected,
    required VoidCallback? onTap,
    required Widget title,
    String? subtitle,
    Widget? leading,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: selected ? AppColors.tint : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 10),
              if (leading != null) ...[leading, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          subtitle,
                          style: m3Text(12, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _addressSection() => OrderSectionCard(
    title: 'Địa chỉ giao hàng',
    icon: Icons.location_on_outlined,
    action: TextButton(
      onPressed: _placing ? null : _manageAddresses,
      child: Text(_addresses.isEmpty ? 'Thêm' : 'Quản lý'),
    ),
    child: _addresses.isEmpty
        ? const Text(
            'Bạn chưa có địa chỉ giao hàng. Hãy thêm một địa chỉ để tiếp tục.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        : Column(
            children: [
              for (final address in _addresses)
                _selectTile(
                  selected: _addressId == address['id'],
                  onTap: _placing
                      ? null
                      : () => setState(
                          () => _addressId = address['id'] as String,
                        ),
                  title: Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '${address['recipientName'] ?? ''} · ${address['phone'] ?? ''}',
                        style: m3Text(13.5, weight: FontWeight.w700),
                      ),
                      if (address['isDefault'] == true)
                        const M3Pill(
                          'Mặc định',
                          color: AppColors.textSecondary,
                          background: Colors.white,
                          fontSize: 10,
                        ),
                    ],
                  ),
                  subtitle: formatAddress(address),
                ),
            ],
          ),
  );

  Widget _bespokeSection() => OrderSectionCard(
    title: 'Sản phẩm chế tác',
    icon: Icons.view_in_ar_outlined,
    child: Row(
      children: [
        const M3IconTile(Icons.view_in_ar_rounded, size: 64, radius: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.bespokeTitle ?? 'Kỷ vật 3D chân dung (Scan AI)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.bespokeSummary != null)
                Text(
                  widget.bespokeSummary!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Text(
          formatVnd(widget.quote?['totalAmount']),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );

  Widget _itemsSection(List<dynamic> items) => OrderSectionCard(
    title: 'Sản phẩm (${items.length})',
    icon: Icons.view_in_ar_outlined,
    child: Column(
      children: [
        for (final raw in items)
          if (raw is Map)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          raw['productName']?.toString() ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${formatVnd(raw['unitPrice'])} × ${raw['quantity'] ?? 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatVnd(raw['subtotal']),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
      ],
    ),
  );

  Widget _paymentSection() => OrderSectionCard(
    title: 'Phương thức thanh toán',
    icon: Icons.account_balance_wallet_outlined,
    child: Column(
      children: [
        for (final method in const ['CASH', 'MOMO', 'ZALOPAY'])
          _selectTile(
            selected: _paymentMethod == method,
            onTap: _placing
                ? null
                : () => setState(() => _paymentMethod = method),
            leading: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: switch (method) {
                  'MOMO' => AppColors.momo,
                  'ZALOPAY' => const Color(0xFF0068FF),
                  _ => AppColors.badgeGreenBg,
                },
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                method == 'CASH'
                    ? Icons.payments_outlined
                    : Icons.account_balance_wallet_rounded,
                size: 16,
                color: method == 'CASH'
                    ? AppColors.badgeGreenText
                    : Colors.white,
              ),
            ),
            title: Text(
              paymentMethodLabels[method] ?? method,
              style: m3Text(13.5, weight: FontWeight.w600),
            ),
          ),
      ],
    ),
  );

  Widget _noteSection() => OrderSectionCard(
    title: 'Ghi chú cho đơn hàng',
    icon: Icons.edit_note_rounded,
    child: M3Field(
      controller: _note,
      enabled: !_placing,
      maxLines: 3,
      maxLength: 255,
      filled: true,
      hint: 'Ví dụ: giao buổi chiều, khắc tên lên đế gỗ…',
    ),
  );

  Widget _summarySection() => OrderSectionCard(
    title: 'Chi tiết thanh toán',
    icon: Icons.receipt_long_outlined,
    child: Column(
      children: _isBespoke
          ? [
              OrderInfoRow(
                label: 'Kỷ vật 3D trọn gói',
                value: formatVnd(widget.quote?['baseAmount']),
              ),
              const OrderInfoRow(label: 'Phí giao hàng', value: 'Miễn phí'),
              const Divider(height: 20, color: AppColors.cardBorder),
              OrderInfoRow(
                label: 'Tổng cộng',
                value: formatVnd(widget.quote?['totalAmount']),
                emphasized: true,
              ),
            ]
          : [
              OrderInfoRow(
                label: 'Tạm tính',
                value: formatVnd(_cart?['subtotal']),
              ),
              OrderInfoRow(
                label: 'Giảm giá',
                value: formatVnd(_cart?['discount']),
              ),
              OrderInfoRow(
                label: 'Phí giao hàng',
                value: formatVnd(_cart?['shippingFee']),
              ),
              const Divider(height: 20, color: AppColors.cardBorder),
              OrderInfoRow(
                label: 'Tổng cộng',
                value: formatVnd(_cart?['total']),
                emphasized: true,
              ),
            ],
    ),
  );
}
