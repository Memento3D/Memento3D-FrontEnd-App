import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/services/order_service.dart';
import '../widgets/order_presentation.dart';
import 'checkout_screen.dart';

/// Entry point of a bespoke print order (UF-06B): pick the keepsake package and
/// its personalization, get a server-side quote, then continue to checkout.
///
/// The quote is mandatory: the backend rejects a scan order that carries a
/// client-side price, so "Tiếp tục đặt hàng" only unlocks once a quote exists.
class PrintOrderConfigScreen extends StatefulWidget {
  const PrintOrderConfigScreen({
    super.key,
    required this.scanId,
    this.scanName,
    this.client,
    this.service,
  });

  final String scanId;
  final String? scanName;
  final ApiClient? client;
  final OrderService? service;

  @override
  State<PrintOrderConfigScreen> createState() => _PrintOrderConfigScreenState();
}

class _PrintOrderConfigScreenState extends State<PrintOrderConfigScreen> {
  /// Option groups shown as single-choice lists, in the order they appear.
  static const _optionTypes = <String, String>{
    'MATERIAL': 'Vật liệu in',
    'BASE': 'Đế trưng bày',
    'PAINTING': 'Hoàn thiện bề mặt',
    'ACCESSORIES': 'Phụ kiện & hộp quà',
    'PACKAGING': 'Đóng gói',
  };

  late final OrderService _service =
      widget.service ?? OrderService(client: widget.client);
  final _engraving = TextEditingController();

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _options = [];
  String? _productId;
  final _selected = <String, Map<String, dynamic>>{};
  double _sizeCm = 15;
  Map<String, dynamic>? _quote;
  bool _busy = true;
  bool _quoting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _engraving.dispose();
    super.dispose();
  }

  String _message(Object error, String fallback) =>
      error is ApiException ? error.message : fallback;

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final products = await _service.loadProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _productId = products.isEmpty ? null : products.first['id'] as String;
      });
      final productId = _productId;
      if (productId != null) await _loadOptions(productId);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(
            error,
            'Không thể tải gói chế tác. Vui lòng thử lại.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadOptions(String productId) async {
    try {
      final options = await _service.loadCustomizationOptions(productId);
      if (!mounted) return;
      setState(() {
        _options = options;
        _selected.clear();
        // Every change of package invalidates the price already quoted.
        _quote = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _options = [];
          _selected.clear();
          _quote = null;
          _error = _message(
            error,
            'Không thể tải tùy chọn cá nhân hóa của gói này.',
          );
        });
      }
    }
  }

  List<Map<String, dynamic>> _optionsOfType(String type) => _options
      .where(
        (option) =>
            option['optionType']?.toString().toUpperCase() == type &&
            option['isActive'] != false,
      )
      .toList();

  Map<String, Object?> _customization() => {
    for (final entry in _selected.entries)
      entry.key.toLowerCase(): entry.value['name'] ?? entry.value['code'],
    'size': '${_sizeCm.round()}cm',
    if (_engraving.text.trim().isNotEmpty) 'engraving': _engraving.text.trim(),
  };

  Future<void> _requestQuote() async {
    final productId = _productId;
    if (_quoting || productId == null) return;
    setState(() {
      _quoting = true;
      _error = null;
    });
    try {
      final quote = await _service.requestQuote(
        productId: productId,
        sizeCm: _sizeCm.round(),
        customization: _customization(),
      );
      if (mounted) setState(() => _quote = quote);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = _message(
            error,
            'Không lấy được báo giá. Vui lòng thử lại.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  void _continue() {
    final quote = _quote;
    if (quote == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          service: _service,
          scanId: widget.scanId,
          quote: quote,
          bespokeTitle: widget.scanName == null
              ? 'Kỷ vật 3D chân dung (Scan AI)'
              : 'Kỷ vật 3D · ${widget.scanName}',
          bespokeSummary:
              '${_sizeCm.round()}cm · ${_selected['MATERIAL']?['name'] ?? 'Vật liệu tiêu chuẩn'}',
        ),
      ),
    );
  }

  static const _optionIcons = <String, IconData>{
    'MATERIAL': Icons.layers_outlined,
    'BASE': Icons.table_restaurant_outlined,
    'PAINTING': Icons.palette_outlined,
    'ACCESSORIES': Icons.card_giftcard_outlined,
    'PACKAGING': Icons.inventory_2_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final quote = _quote;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const M3TopBar(title: 'Cấu hình đơn in 3D'),
      body: Column(
        children: [
          if (_busy || _quoting) const LinearProgressIndicator(minHeight: 2),
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
            child: _products.isEmpty && !_busy
                ? const Center(
                    child: Text('Chưa có gói chế tác nào để đặt in.'),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _modelCard(),
                      _packageCard(),
                      _sizeCard(),
                      for (final entry in _optionTypes.entries)
                        if (_optionsOfType(entry.key).isNotEmpty)
                          _optionCard(entry.key, entry.value),
                      _engravingCard(),
                      _quoteCard(quote),
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
            child: quote == null
                ? M3Button(
                    label: _quoting ? 'Đang báo giá…' : 'Nhận báo giá',
                    style: M3ButtonStyle.solid,
                    trailing: _quoting ? null : Icons.arrow_forward_rounded,
                    onPressed: _busy || _quoting || _productId == null
                        ? null
                        : _requestQuote,
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tạm tính',
                              style: m3Text(12, color: AppColors.textSecondary),
                            ),
                            Text(
                              formatVnd(quote['totalAmount']),
                              style: m3Text(
                                20,
                                weight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      M3Button(
                        label: 'Tiếp tục đặt hàng',
                        style: M3ButtonStyle.solid,
                        expand: false,
                        onPressed: _continue,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _choiceTile({
    required bool selected,
    required VoidCallback? onTap,
    required String title,
    String? subtitle,
    String? trailing,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: selected ? AppColors.tint : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: m3Text(13.5, weight: FontWeight.w700)),
                    if (subtitle != null && subtitle.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle,
                          style: m3Text(
                            12,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                Text(
                  trailing,
                  style: m3Text(
                    13,
                    weight: FontWeight.w700,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Widget _modelCard() => M3Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        const M3IconTile(Icons.view_in_ar_rounded, size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MÔ HÌNH ĐẶT IN',
                style: m3Text(
                  10.5,
                  weight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.scanName ?? 'Phiên scan ${widget.scanId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: m3Text(16, weight: FontWeight.w700),
              ),
              Text(
                '# Mã phiên: ${widget.scanId}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: m3Text(11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _packageCard() => OrderSectionCard(
    title: 'Gói chế tác',
    icon: Icons.workspace_premium_outlined,
    action: Text(
      'Bắt buộc',
      style: m3Text(11.5, weight: FontWeight.w600, color: AppColors.primary),
    ),
    child: Column(
      children: [
        for (final product in _products)
          _choiceTile(
            selected: _productId == product['id'],
            onTap: () {
              final value = product['id'] as String;
              if (_busy || value == _productId) return;
              setState(() => _productId = value);
              _loadOptions(value);
            },
            title: product['name']?.toString() ?? '',
            subtitle: product['shortDescription']?.toString(),
            trailing: formatVnd(product['price']),
          ),
      ],
    ),
  );

  Widget _sizeCard() => OrderSectionCard(
    title: 'Kích thước tượng',
    icon: Icons.straighten_rounded,
    action: Text(
      '${_sizeCm.round()} cm',
      style: m3Text(14, weight: FontWeight.w800, color: AppColors.primary),
    ),
    child: Slider(
      value: _sizeCm,
      min: 10,
      max: 30,
      divisions: 20,
      label: '${_sizeCm.round()} cm',
      onChanged: _quoting
          ? null
          : (value) => setState(() {
              _sizeCm = value;
              _quote = null;
            }),
    ),
  );

  Widget _optionCard(String type, String title) {
    final options = _optionsOfType(type);
    return OrderSectionCard(
      title: title,
      icon: _optionIcons[type],
      child: Column(
        children: [
          for (final option in options)
            _choiceTile(
              selected: _selected[type]?['id'] == option['id'],
              onTap: _quoting
                  ? null
                  : () => setState(() {
                      _selected[type] = option;
                      _quote = null;
                    }),
              title: option['name']?.toString() ?? '',
              subtitle:
                  ((option['additionalPrice'] as num?)?.toDouble() ?? 0) > 0
                  ? '+ ${formatVnd(option['additionalPrice'])}'
                  : 'Bao gồm sẵn',
            ),
        ],
      ),
    );
  }

  Widget _engravingCard() => OrderSectionCard(
    title: 'Khắc tên trên đế',
    icon: Icons.short_text_rounded,
    action: Text(
      'Tùy chọn',
      style: m3Text(11.5, color: AppColors.textSecondary),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Khắc laser chìm mạ nhũ vàng sắc nét trên mặt trước của đế trưng bày.',
          style: m3Text(12, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 10),
        M3Field(
          controller: _engraving,
          enabled: !_quoting,
          maxLength: 60,
          hint: 'Ví dụ: Gia đình An · 2026',
          filled: true,
          onChanged: (_) {
            if (_quote != null) setState(() => _quote = null);
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _engraving,
              builder: (_, value, _) => Text(
                '${value.text.length}/60',
                style: m3Text(11, color: AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _quoteCard(Map<String, dynamic>? quote) => quote == null
      ? M3Card(
          color: AppColors.tint.withValues(alpha: 0.6),
          borderColor: AppColors.tintStrong.withValues(alpha: 0.5),
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const M3IconTile(
                Icons.info_outline_rounded,
                size: 36,
                radius: 18,
                background: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Báo giá', style: m3Text(15, weight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      'Chọn cấu hình rồi nhấn "Nhận báo giá" để hệ thống tính giá theo thể tích, vật liệu và phí vận chuyển.',
                      style: m3Text(
                        12.5,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      : OrderSectionCard(
          title: 'Báo giá',
          icon: Icons.receipt_long_outlined,
          child: Column(
            children: [
              OrderInfoRow(
                label: 'Giá chế tác cơ bản',
                value: formatVnd(quote['baseAmount']),
              ),
              OrderInfoRow(
                label: 'Phí cá nhân hóa',
                value: formatVnd(quote['customizationAmount']),
              ),
              OrderInfoRow(
                label: 'Phí vận chuyển',
                value: formatVnd(quote['shippingAmount']),
              ),
              const Divider(height: 20, color: AppColors.cardBorder),
              OrderInfoRow(
                label: 'Tổng cộng',
                value: formatVnd(quote['totalAmount']),
                emphasized: true,
              ),
              if (quote['validUntil'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Báo giá có hiệu lực đến ${quote['validUntil']}',
                    style: m3Text(12, color: AppColors.textMuted),
                  ),
                ),
            ],
          ),
        );
}
