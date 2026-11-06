import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../orders/presentation/screens/order_detail_screen.dart';
import '../data/customization_api.dart';

/// Explicitly freezes the server-saved revision. No client prices or asset URLs.
class CustomPrintCheckoutScreen extends StatefulWidget {
  const CustomPrintCheckoutScreen({
    super.key,
    required this.scene,
    required this.draft,
    this.client,
  });
  final DesignScene scene;
  final DesignDraft draft;
  final ApiClient? client;
  @override
  State<CustomPrintCheckoutScreen> createState() =>
      _CustomPrintCheckoutScreenState();
}

class _CustomPrintCheckoutScreenState extends State<CustomPrintCheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(),
      _phone = TextEditingController(),
      _address = TextEditingController(),
      _note = TextEditingController(),
      _height = TextEditingController(text: '12');
  late final ApiClient _client = widget.client ?? ApiClient();
  bool _loading = true, _busy = false, _confirmed = false;
  String? _error;
  Map<String, dynamic>? _pending;
  late final String _newKey =
      'custom:${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  String get _storageKey =>
      'memento3d:pending-checkout:${widget.scene.outputId}:${widget.scene.fitId}:${widget.draft.revision}';
  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (data['modelOutputId'] == widget.scene.outputId &&
            data['fitResultId'] == widget.scene.fitId &&
            data['customizationRevision'] == widget.draft.revision &&
            data['idempotencyKey'] is String) {
          _pending = data;
          _name.text = data['recipientName'] as String;
          _phone.text = data['phone'] as String;
          _address.text = data['shippingAddress'] as String;
          _note.text = data['note'] as String? ?? '';
          _height.text = '${data['requestedHeightCm']}';
          _confirmed = true;
        }
      }
    } catch (_) {
      /* Recovery is optional; server revision is always authoritative. */
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _send() async {
    if (_busy ||
        (!_confirmed && _pending == null) ||
        !_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final payload =
        _pending ??
        {
          'modelOutputId': widget.scene.outputId,
          'fitResultId': widget.scene.fitId,
          'customizationRevision': widget.draft.revision,
          'requestedHeightCm': int.parse(_height.text),
          'recipientName': _name.text.trim(),
          'phone': _phone.text.trim(),
          'shippingAddress': _address.text.trim(),
          'note': _note.text.trim(),
          'idempotencyKey': _newKey,
        };
    _pending = payload;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(payload));
    } catch (_) {}
    try {
      final result = Map<String, dynamic>.from(
        await _client.post('/api/v1/orders', body: payload) as Map,
      );
      final id = result['id'] as String;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_storageKey);
      } catch (_) {}
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailScreen(orderId: id, client: _client),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException && error.statusCode == 409
              ? 'Bản lưu hoặc yêu cầu đã thay đổi. Quay về tải lại bản đã lưu trước khi gửi tiếp.'
              : 'Chưa xác nhận được yêu cầu. Gửi lại cùng yêu cầu để tránh tạo đơn trùng.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _note, _height]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Vui lòng điền thông tin' : null;
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Scaffold(
      appBar: AppBar(title: const Text('Chốt thiết kế đặt sản xuất')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Xưởng kiểm tra và báo giá trước khi thanh toán.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Đơn giữ đúng bản thiết kế này. Sửa model cá nhân sau đó không làm thay đổi mẫu đã gửi xưởng.',
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text('Bản lưu #${widget.draft.revision}')),
                      for (final asset in widget.scene.assets.where(
                        (a) => widget.draft.selection.containsValue(
                          a['assetVersionId'],
                        ),
                      ))
                        Chip(label: Text(asset['name'] as String)),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (_pending != null)
                    const Text(
                      'Yêu cầu đang chờ xác nhận. Gửi lại sẽ dùng nguyên nội dung và mã yêu cầu trước đó.',
                    ),
                  TextFormField(
                    controller: _name,
                    enabled: !_busy && _pending == null,
                    maxLength: 255,
                    decoration: const InputDecoration(labelText: 'Người nhận'),
                    validator: _required,
                  ),
                  TextFormField(
                    controller: _phone,
                    enabled: !_busy && _pending == null,
                    keyboardType: TextInputType.phone,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                    validator: (v) =>
                        v != null && RegExp(r'^[0-9+()\-\s]{8,20}$').hasMatch(v)
                        ? null
                        : 'Kiểm tra lại số điện thoại',
                  ),
                  TextFormField(
                    controller: _address,
                    enabled: !_busy && _pending == null,
                    maxLines: 2,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      labelText: 'Địa chỉ nhận',
                    ),
                    validator: _required,
                  ),
                  TextFormField(
                    controller: _height,
                    enabled: !_busy && _pending == null,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Chiều cao toàn mẫu mong muốn (cm)',
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      return n != null && n >= 8 && n <= 20
                          ? null
                          : 'Chọn chiều cao từ 8 đến 20 cm';
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Vật liệu dự kiến: Resin SLA. Xưởng sẽ xác nhận khả năng in, chi phí và thời gian thực hiện.',
                    ),
                  ),
                  TextFormField(
                    controller: _note,
                    enabled: !_busy && _pending == null,
                    maxLines: 2,
                    maxLength: 2000,
                    decoration: const InputDecoration(labelText: 'Ghi chú'),
                  ),
                  CheckboxListTile(
                    value: _confirmed,
                    onChanged: _busy || _pending != null
                        ? null
                        : (value) =>
                              setState(() => _confirmed = value ?? false),
                    title: const Text(
                      'Tôi xác nhận gửi đúng bản thiết kế đã lưu ở trên.',
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _loading || _busy || !_confirmed ? null : _send,
            child: Text(
              _busy
                  ? 'Đang gửi…'
                  : _pending != null
                  ? 'Gửi lại cùng yêu cầu'
                  : 'Gửi yêu cầu đặt sản xuất',
            ),
          ),
        ),
      ),
    ),
  );
}
