import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../model_viewer/data/services/model_download_service.dart';
import '../../model_viewer/presentation/models/model_viewer_data.dart';
import '../../model_viewer/presentation/screens/model_viewer_screen.dart';

bool isCustomPrintOrder(Map<String, dynamic> order) =>
    (order['items'] as List? ?? []).whereType<Map>().any((item) {
      final data = item['customization'] ?? item['customizationSnapshot'];
      return data is Map && data['kind'] == 'CUSTOM_PRINT_V1';
    });

class FrozenOrderDesignPanel extends StatefulWidget {
  const FrozenOrderDesignPanel({super.key, required this.orderId, this.client});
  final String orderId;
  final ApiClient? client;
  @override
  State<FrozenOrderDesignPanel> createState() => _FrozenOrderDesignPanelState();
}

class _FrozenOrderDesignPanelState extends State<FrozenOrderDesignPanel>
    with WidgetsBindingObserver {
  late final ApiClient _api = widget.client ?? ApiClient();
  Map<String, dynamic>? _design;
  String? _error;
  Timer? _timer;
  bool _loading = false, _previewing = false, _paused = false;
  String get _path =>
      '/api/v1/orders/${Uri.encodeComponent(widget.orderId)}/custom-design';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _timer?.cancel();
    } else {
      unawaited(_load());
    }
  }

  Future<void> _load({bool retry = false}) async {
    if (_loading) return;
    _timer?.cancel();
    setState(() => _loading = true);
    try {
      final data = Map<String, dynamic>.from(
        (retry ? await _api.post('$_path/retry') : await _api.get(_path))
            as Map,
      );
      if (mounted) {
        setState(() {
          _design = data;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Chưa tải được thiết kế của đơn.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (!_paused &&
            ['QUEUED', 'EXPORTING', 'READY'].contains(_design?['status'])) {
          _timer = Timer(const Duration(seconds: 5), () => unawaited(_load()));
        }
      }
    }
  }

  Future<void> _preview() async {
    if (_previewing || _design?['downloadUrl'] == null) return;
    setState(() => _previewing = true);
    final downloader = ModelDownloadService();
    File? file;
    try {
      try {
        file = await downloader.downloadGlb(
          url: _design!['downloadUrl'] as String,
          onProgress: (_, _) {},
        );
      } on ApiException catch (error) {
        if (error.statusCode != 401 && error.statusCode != 403) rethrow;
        await _load();
        file = await downloader.downloadGlb(
          url: _design!['downloadUrl'] as String,
          onProgress: (_, _) {},
        );
      }
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ModelViewerScreen(
            modelUrl: file!.uri.toString(),
            data: const ModelViewerData(
              modelName: 'Mẫu đã chốt trong đơn',
              availability: ModelAvailability.ready,
              format: ModelFileFormat.glb,
              completionPercentage: 100,
            ),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Chưa xem được file. Hãy làm mới thiết kế của đơn và thử lại.',
        );
      }
    } finally {
      downloader.dispose();
      if (file != null) {
        try {
          await file.delete();
          await file.parent.delete();
        } catch (_) {}
      }
      if (mounted) setState(() => _previewing = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final design = _design;
    final label =
        {
          'QUEUED': 'Chờ chuẩn bị file',
          'EXPORTING': 'Đang chuẩn bị file',
          'READY': 'Chờ xưởng kiểm tra file',
          'APPROVED': 'File đã được xưởng duyệt',
          'REJECTED': 'File cần điều chỉnh',
          'FAILED': 'Chưa chuẩn bị được file',
        }[design?['status']] ??
        'Đang tải thiết kế';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Thiết kế đã chốt trong đơn',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : () => unawaited(_load()),
                  tooltip: 'Làm mới file',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            if (_loading) const LinearProgressIndicator(),
            Text(label),
            if (design != null) ...[
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text('Bản lưu #${design['revision']}')),
                  Chip(label: Text('${design['requestedHeightCm']} cm')),
                  for (final asset
                      in (design['assets'] as List).whereType<Map>())
                    Chip(label: Text(asset['name'] as String)),
                ],
              ),
              const Text(
                'Đây là bản cố định đã gửi xưởng. Sửa model cá nhân sau đó không làm thay đổi bản trong đơn.',
              ),
              if (design['reviewNotes'] != null)
                Text('Nhận xét của xưởng: ${design['reviewNotes']}'),
              if (design['downloadUrl'] != null)
                FilledButton.tonal(
                  onPressed: _previewing ? null : _preview,
                  child: Text(_previewing ? 'Đang mở mẫu…' : 'Xem mẫu đã chốt'),
                ),
              if (design['status'] == 'FAILED')
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => unawaited(_load(retry: true)),
                  child: const Text('Thử chuẩn bị lại file'),
                ),
            ],
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
