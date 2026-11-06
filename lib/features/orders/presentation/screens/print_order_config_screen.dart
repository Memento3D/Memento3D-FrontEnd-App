import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../../../../core/network/api_client.dart';
import '../../data/services/order_service.dart';
import '../widgets/order_presentation.dart';
import 'checkout_screen.dart';

/// Entry point of a bespoke print order: pick size and personalization, then
/// continue to checkout. The keepsake has one flat price ([kBespokePrintPrice]),
/// so there is no package choice and no quote step.
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
  static const _optionTypes = <String, String>{
    'MATERIAL': 'Vật liệu in',
    'BASE': 'Đế trưng bày',
    'PAINTING': 'Hoàn thiện bề mặt',
    'ACCESSORIES': 'Phụ kiện & hộp quà',
    'PACKAGING': 'Đóng gói',
  };

  static const _optionIcons = <String, IconData>{
    'MATERIAL': Icons.layers_outlined,
    'BASE': Icons.table_restaurant_outlined,
    'PAINTING': Icons.palette_outlined,
    'ACCESSORIES': Icons.card_giftcard_outlined,
    'PACKAGING': Icons.inventory_2_outlined,
  };

  static const _inclusions = <(IconData, String)>[
    (Icons.view_in_ar_rounded, 'In 3D từ mô hình của bạn'),
    (Icons.card_giftcard_outlined, 'Hộp quà & đóng gói cẩn thận'),
    (Icons.local_shipping_outlined, 'Miễn phí vận chuyển toàn quốc'),
  ];

  late final OrderService _service =
      widget.service ?? OrderService(client: widget.client);
  final _engraving = TextEditingController();

  List<Map<String, dynamic>> _options = [];
  final _selected = <String, Map<String, dynamic>>{};
  double _sizeCm = 15;
  bool _loadingOptions = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _engraving.dispose();
    super.dispose();
  }

  /// Options are cosmetic choices only; failing to load them never blocks the
  /// order, the workshop falls back to the standard finish.
  Future<void> _loadOptions() async {
    try {
      final products = await _service.loadProducts();
      if (products.isEmpty) return;
      final options = await _service.loadCustomizationOptions(
        products.first['id'] as String,
      );
      if (mounted) setState(() => _options = options);
    } catch (_) {
      // Keep the standard configuration.
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  List<Map<String, dynamic>> _optionsOfType(String type) => _options
      .where(
        (option) =>
            option['optionType']?.toString().toUpperCase() == type &&
            option['isActive'] != false,
      )
      .toList();

  String _configSummary() {
    final parts = <String>[
      'Kích thước ${_sizeCm.round()}cm',
      for (final entry in _optionTypes.entries)
        if (_selected[entry.key] != null)
          '${entry.value}: ${_selected[entry.key]!['name'] ?? _selected[entry.key]!['code']}',
      if (_engraving.text.trim().isNotEmpty)
        'Khắc tên: ${_engraving.text.trim()}',
    ];
    return parts.join(' · ');
  }

  void _continue() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutScreen(
          service: _service,
          scanId: widget.scanId,
          quote: const {
            'baseAmount': kBespokePrintPrice,
            'customizationAmount': 0,
            'shippingAmount': 0,
            'totalAmount': kBespokePrintPrice,
          },
          bespokeTitle: widget.scanName == null
              ? 'Kỷ vật 3D chân dung (Scan AI)'
              : 'Kỷ vật 3D · ${widget.scanName}',
          bespokeSummary:
              '${_sizeCm.round()}cm · ${_selected['MATERIAL']?['name'] ?? 'Vật liệu tiêu chuẩn'}',
          bespokeNote: _configSummary(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const M3TopBar(title: 'Đặt in kỷ vật 3D'),
      body: Column(
        children: [
          if (_loadingOptions) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _heroCard(),
                _sizeCard(),
                for (final entry in _optionTypes.entries)
                  if (_optionsOfType(entry.key).isNotEmpty)
                    _optionCard(entry.key, entry.value),
                _engravingCard(),
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
                      Text(
                        'Trọn gói',
                        style: m3Text(12, color: AppColors.textSecondary),
                      ),
                      Text(
                        formatVnd(kBespokePrintPrice),
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
                  trailing: Icons.arrow_forward_rounded,
                  onPressed: _continue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Model + flat price + what is included, in one glance.
  Widget _heroCard() => M3Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const M3IconTile(Icons.view_in_ar_rounded, size: 52),
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
                ],
              ),
            ),
            Text(
              formatVnd(kBespokePrintPrice),
              style: m3Text(
                17,
                weight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppColors.cardBorder),
        const SizedBox(height: 12),
        for (final (icon, text) in _inclusions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: m3Text(13))),
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.badgeGreenText,
                ),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _choiceTile({
    required bool selected,
    required VoidCallback onTap,
    required String title,
    String? subtitle,
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
            ],
          ),
        ),
      ),
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
      onChanged: (value) => setState(() => _sizeCm = value),
    ),
  );

  Widget _optionCard(String type, String title) => OrderSectionCard(
    title: title,
    icon: _optionIcons[type],
    action: Text(
      'Tùy chọn',
      style: m3Text(11.5, color: AppColors.textSecondary),
    ),
    child: Column(
      children: [
        for (final option in _optionsOfType(type))
          _choiceTile(
            selected: _selected[type]?['id'] == option['id'],
            onTap: () => setState(() => _selected[type] = option),
            title: option['name']?.toString() ?? '',
            subtitle: option['description']?.toString(),
          ),
      ],
    ),
  );

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
          maxLength: 60,
          hint: 'Ví dụ: Gia đình An · 2026',
          filled: true,
        ),
      ],
    ),
  );
}
