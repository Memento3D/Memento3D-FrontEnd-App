import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/m3_ui.dart';
import '../../../../core/network/api_exception.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key, this.client});
  final ApiClient? client;

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  static const _base = '/api/v1/users/me/addresses';
  late final ApiClient _client = widget.client ?? ApiClient();
  List<Map<String, dynamic>> _addresses = [];
  bool _busy = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _message(Object error) => error is ApiException
      ? error.message
      : 'Không thể tải địa chỉ. Vui lòng thử lại.';

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await _client.get(_base);
      if (response is! List) {
        throw const FormatException('Invalid address list');
      }
      final addresses = response.map((item) {
        if (item is! Map || item['id'] is! String) {
          throw const FormatException('Invalid address');
        }
        return Map<String, dynamic>.from(item);
      }).toList();
      if (mounted) setState(() => _addresses = addresses);
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(Future<dynamic> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) await _load();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = _message(error);
        });
      }
    }
  }

  Future<void> _edit([Map<String, dynamic>? address]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _AddressForm(client: _client, address: address),
      ),
    );
    if (result == true && mounted) await _load();
  }

  Future<void> _delete(Map<String, dynamic> address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa địa chỉ?'),
        content: const Text('Địa chỉ này sẽ được xóa khỏi sổ địa chỉ.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await _action(
        () => _client.delete(
          '$_base/${Uri.encodeComponent(address['id'] as String)}',
        ),
      );
    }
  }

  Future<void> _makeDefault(Map<String, dynamic> address) => _action(
    () => _client.patch(
      '$_base/${Uri.encodeComponent(address['id'] as String)}/default',
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: const M3TopBar(title: 'Địa chỉ giao hàng'),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _busy ? null : () => _edit(),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_location_alt_outlined),
      label: const Text('Thêm địa chỉ'),
    ),
    body: Column(
      children: [
        if (_busy) const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          ListTile(
            title: Text(_error!),
            trailing: TextButton(
              onPressed: _busy ? null : _load,
              child: const Text('Thử lại'),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                if (_addresses.isEmpty && !_busy && _error == null)
                  _emptyState()
                else ...[
                  for (final address in _addresses) _addressCard(address),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.tint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 17,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Mô hình 3D hoàn thiện sẽ được đóng gói chống sốc và gửi về địa chỉ mặc định của bạn.',
                            style: m3Text(12, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _emptyState() => M3Card(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
    child: Column(
      children: [
        const M3IconTile(Icons.location_off_outlined, size: 64, radius: 32),
        const SizedBox(height: 14),
        Text(
          'Bạn chưa có địa chỉ giao hàng.',
          textAlign: TextAlign.center,
          style: m3Text(16, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          'Thêm địa chỉ nhận các kỷ vật và mô hình in 3D được gửi trực tiếp tới tận tay bạn.',
          textAlign: TextAlign.center,
          style: m3Text(12.5, color: AppColors.textSecondary, height: 1.45),
        ),
      ],
    ),
  );

  Widget _addressCard(Map<String, dynamic> a) {
    final isDefault = a['isDefault'] == true;
    final label = a['label']?.toString();
    final labelText = switch (label) {
      'OFFICE' => 'Văn phòng',
      'OTHER' => 'Xưởng chế tác',
      _ => 'Nhà riêng',
    };
    return M3Card(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                label == 'OFFICE'
                    ? Icons.apartment_rounded
                    : label == 'OTHER'
                    ? Icons.precision_manufacturing_outlined
                    : Icons.home_outlined,
                size: 19,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${a['recipientName'] ?? ''} · ${a['phone'] ?? ''}',
                  style: m3Text(15, weight: FontWeight.w700),
                ),
              ),
              if (isDefault)
                const M3Pill(
                  'Địa chỉ mặc định',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.badgeGreenText,
                  background: AppColors.badgeGreenBg,
                  fontSize: 10.5,
                )
              else
                M3Pill(
                  labelText,
                  color: AppColors.textSecondary,
                  background: AppColors.tint,
                  fontSize: 10.5,
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 25, top: 4),
            child: Text(
              a['formattedAddress']?.toString() ??
                  '${a['streetAddress'] ?? ''}, ${a['ward'] ?? ''}, ${a['province'] ?? ''}',
              style: m3Text(12.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isDefault)
                TextButton.icon(
                  onPressed: _busy ? null : () => _makeDefault(a),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: const Text('Đặt mặc định'),
                ),
              TextButton.icon(
                onPressed: _busy ? null : () => _edit(a),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Sửa'),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _delete(a),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                label: const Text('Xóa'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressForm extends StatefulWidget {
  const _AddressForm({required this.client, this.address});
  final ApiClient client;
  final Map<String, dynamic>? address;
  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  bool _busy = false;
  String? _error;
  late String _label = widget.address?['label']?.toString() ?? 'HOME';

  static const _labels = {
    'recipientName': 'Tên người nhận',
    'phone': 'Số điện thoại',
    'province': 'Tỉnh / Thành phố',
    'ward': 'Phường / Xã',
    'streetAddress': 'Địa chỉ chi tiết',
  };
  static const _hints = {
    'recipientName': 'Ví dụ: Nguyễn Văn An',
    'phone': '0912 345 678',
    'province': 'Chọn hoặc nhập Tỉnh / Thành',
    'ward': 'Phường / Xã / Thị trấn',
    'streetAddress': 'Số nhà, tên đường, toà nhà, căn hộ...',
  };
  static const _icons = {
    'recipientName': Icons.badge_outlined,
    'phone': Icons.phone_outlined,
    'province': Icons.location_city_outlined,
    'ward': Icons.explore_outlined,
    'streetAddress': Icons.location_on_outlined,
  };
  static const _labelOptions = {
    'HOME': 'Nhà riêng',
    'OFFICE': 'Văn phòng',
    'OTHER': 'Xưởng chế tác',
  };

  @override
  void initState() {
    super.initState();
    for (final key in _labels.keys) {
      _fields[key] = TextEditingController(
        text: widget.address?[key]?.toString() ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final body = <String, dynamic>{
        ..._fields.map((key, value) => MapEntry(key, value.text.trim())),
        'label': _label,
      };
      final id = widget.address?['id'];
      if (id == null) {
        await widget.client.post(_AddressesScreenState._base, body: body);
      } else {
        await widget.client.patch(
          '${_AddressesScreenState._base}/${Uri.encodeComponent(id as String)}',
          body: body,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không thể lưu địa chỉ. Vui lòng thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: M3TopBar(
      title: widget.address == null ? 'Thêm địa chỉ' : 'Sửa địa chỉ',
    ),
    body: Form(
      key: _form,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            M3Card(
              color: AppColors.tint.withValues(alpha: 0.6),
              borderColor: AppColors.tintStrong.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const M3IconTile(
                    Icons.local_shipping_outlined,
                    background: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Giao nhận kỷ vật 3D an toàn',
                          style: m3Text(15, weight: FontWeight.w700),
                        ),
                        Text(
                          'Tác phẩm in resin/đúc được đóng gói chống sốc',
                          style: m3Text(11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            M3Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final entry in _labels.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: M3Field(
                        key: ValueKey('address-${entry.key}'),
                        label: entry.value,
                        hint: _hints[entry.key],
                        controller: _fields[entry.key],
                        enabled: !_busy,
                        filled: true,
                        showCounter: true,
                        maxLines: entry.key == 'streetAddress' ? 3 : 1,
                        suffix: Icon(
                          _icons[entry.key],
                          size: 19,
                          color: AppColors.textMuted,
                        ),
                        keyboardType: entry.key == 'phone'
                            ? TextInputType.phone
                            : TextInputType.text,
                        maxLength: entry.key == 'phone'
                            ? 30
                            : entry.key == 'streetAddress'
                            ? 255
                            : 100,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập ${entry.value.toLowerCase()}.'
                            : null,
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final option in _labelOptions.entries)
                        ChoiceChip(
                          label: Text(option.value),
                          selected: _label == option.key,
                          showCheckmark: false,
                          selectedColor: AppColors.tintStrong,
                          backgroundColor: AppColors.tint,
                          side: BorderSide.none,
                          shape: const StadiumBorder(),
                          labelStyle: m3Text(
                            12,
                            weight: FontWeight.w600,
                            color: _label == option.key
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          onSelected: _busy
                              ? null
                              : (_) => setState(() => _label = option.key),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: m3Text(13, color: AppColors.error)),
              ),
            const SizedBox(height: 18),
            M3Button(
              label: _busy ? 'Đang lưu…' : 'Lưu địa chỉ',
              style: M3ButtonStyle.solid,
              leading: Icons.save_outlined,
              onPressed: _busy ? null : _save,
            ),
          ],
        ),
      ),
    ),
  );
}
