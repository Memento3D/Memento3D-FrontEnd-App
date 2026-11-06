import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../reconstruction/data/real_execution_guard.dart';
import 'customization_screen.dart';
import '../data/customization_api.dart';

const _viewLabels = {
  'front': 'Chính diện',
  'left': 'Nghiêng trái',
  'right': 'Nghiêng phải',
  'back': 'Phía sau (tùy chọn)',
};

class CreateModelScreen extends StatefulWidget {
  const CreateModelScreen({super.key, this.scanId, this.scanName, this.api});
  final String? scanId, scanName;
  final ApiClient? api;
  @override
  State<CreateModelScreen> createState() => _CreateModelScreenState();
}

class _CreateModelScreenState extends State<CreateModelScreen> {
  late final ApiClient _api;
  final _picker = ImagePicker();
  final _images = <String, XFile>{}, _uploaded = <String, String>{};
  Map<String, dynamic>? _capabilities;
  String? _scanId, _error;
  String _phase = 'Tạo phiên';
  bool _busy = false, _consent = false, _submitted = false;
  double _upload = 0;
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiClient();
    _scanId = widget.scanId;
    unawaited(_loadCapabilities());
  }

  Future<void> _loadCapabilities() async {
    try {
      final value = Map<String, dynamic>.from(
        await _api.get('/api/v1/reconstruction/capabilities') as Map,
      );
      if (value['supportedFormats'] is! List ||
          value['maxFileSizeMb'] is! num ||
          value['maxImages'] is! int) {
        throw const FormatException('Cấu hình ảnh không hợp lệ');
      }
      if (mounted) {
        setState(() {
          _capabilities = value;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : 'Không lấy được cấu hình ảnh. Hãy thử lại.',
        );
      }
    }
  }

  String _mime(XFile file) {
    if (file.mimeType != null) return file.mimeType!;
    final name = file.name.toLowerCase();
    return name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.webp')
        ? 'image/webp'
        : name.endsWith('.jpg') || name.endsWith('.jpeg')
        ? 'image/jpeg'
        : 'application/octet-stream';
  }

  Future<void> _pick(String view, ImageSource source) async {
    if (_busy || _capabilities == null) return;
    try {
      final file = await _picker.pickImage(source: source);
      if (file == null || !mounted) return;
      if (!(_capabilities!['supportedFormats'] as List).contains(_mime(file))) {
        throw const FormatException('Định dạng ảnh chưa được hỗ trợ.');
      }
      if (await file.length() >
          (_capabilities!['maxFileSizeMb'] as num) * 1024 * 1024) {
        throw FormatException(
          'Ảnh vượt ${_capabilities!['maxFileSizeMb']} MiB.',
        );
      }
      if (!mounted) return;
      setState(() {
        if (_uploaded.isNotEmpty) {
          _scanId = null;
          _uploaded.clear();
          _submitted = false;
        }
        _images[view] = file;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is FormatException ? error.message : 'Không mở được camera/thư viện. Bạn có thể thử chọn ảnh từ thiết bị.',
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_busy ||
        !_consent ||
        _capabilities == null ||
        !['front', 'left', 'right'].every(_images.containsKey)) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _upload = 0;
      _phase = 'Tạo phiên';
    });
    try {
      if (_scanId == null) {
        final scan = Map<String, dynamic>.from(
          await _api.post(
            '/api/v1/scans',
            body: {
              'name':
                  widget.scanName ??
                  'Kỷ vật 3D ${DateTime.now().toIso8601String().substring(0, 10)}',
              'input_mode': 'image',
            },
          ) as Map,
        );
        _scanId = scan['id'] as String;
      }
      var completed = 0;
      for (final entry in _images.entries) {
        if (!mounted) return;
        if (!_uploaded.containsKey(entry.key)) {
          setState(() => _phase = 'Tải ảnh ${_viewLabels[entry.key]}');
          final file = http.MultipartFile.fromBytes(
            'file',
            await entry.value.readAsBytes(),
            filename: entry.value.name,
            contentType: MediaType.parse(_mime(entry.value)),
          );
          final response = Map<String, dynamic>.from(
            await _api.postMultipart(
              '/api/v1/scans/$_scanId/images?view_hint=${entry.key}',
              files: [file],
              expectedStatusCode: 201,
            ) as Map,
          );
          _uploaded[entry.key] = (response['image'] as Map)['id'] as String;
        }
        completed++;
        if (mounted) setState(() => _upload = completed / _images.length);
      }
      if (mounted) setState(() => _phase = 'Tạo tác vụ dựng hình');
      Map<String, dynamic>? job;
      if (!mounted) return;
      if (_submitted) {
        try {
          job = Map<String, dynamic>.from(
            await _api.get('/api/v1/scans/$_scanId/reconstruction-jobs') as Map,
          );
        } on ApiException catch (error) {
          if (error.statusCode != 404) rethrow;
        }
      }
      if (job == null) {
        _submitted = true;
        job = Map<String, dynamic>.from(
          await _api.post(
            '/api/v1/reconstructions/previews',
            body: {
              'scanId': _scanId,
              'inputImageId': _uploaded['front'],
              'profile': 'preview',
            },
          ) as Map,
        );
      }
      requireRealExecution(job);
      final id = job['job_id'] as String;
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              ModelProgressScreen(scanId: _scanId!, jobId: id, api: _api),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error is ApiException
              ? '$_phase: ${error.message} (HTTP ${error.statusCode})'
              : error is FormatException
              ? '$_phase: ${error.message}'
              : '$_phase chưa thành công. Giữ nguyên bộ ảnh và thử lại.';
        });
      }
    }
  }

  static const _viewHints = {
    'front': 'Nhìn thẳng vào ống kính',
    'left': 'Quay mặt sang trái khoảng 45°',
    'right': 'Quay mặt sang phải khoảng 45°',
    'back': 'Giúp tái tạo phần sau đầu',
  };
  static const _requiredViews = ['front', 'left', 'right'];

  int get _doneCount => _requiredViews.where(_images.containsKey).length;
  bool get _canSubmit =>
      !_busy && _capabilities != null && _consent && _doneCount == 3;

  void _remove(String view) {
    if (_busy) return;
    setState(() {
      _images.remove(view);
      if (_uploaded.isNotEmpty) {
        _scanId = null;
        _uploaded.clear();
        _submitted = false;
      }
    });
  }

  Future<void> _choose(String view) async {
    if (_busy || _capabilities == null) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh mới'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            if (_images.containsKey(view))
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: const Text('Xóa ảnh này'),
                onTap: () {
                  Navigator.pop(ctx);
                  _remove(view);
                },
              ),
          ],
        ),
      ),
    );
    if (source != null) await _pick(view, source);
  }

  Widget _slot(String view) {
    final scheme = Theme.of(context).colorScheme;
    final file = _images[view];
    final optional = view == 'back';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _busy || _capabilities == null ? null : () => _choose(view),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 92,
                  height: 92,
                  color: scheme.surfaceContainerHighest,
                  child: file != null
                      ? Image.file(File(file.path), fit: BoxFit.cover)
                      : Icon(
                          Icons.add_a_photo_outlined,
                          size: 30,
                          color: scheme.onSurfaceVariant,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _viewLabels[view]!,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _viewHints[view]!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    if (file != null)
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đã chọn · bấm để đổi',
                            style: TextStyle(color: scheme.primary),
                          ),
                        ],
                      )
                    else
                      Text(
                        optional ? 'Tùy chọn' : 'Bắt buộc · bấm để thêm',
                        style: TextStyle(
                          color: optional
                              ? scheme.onSurfaceVariant
                              : scheme.error,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showBack = (_capabilities?['maxImages'] as int? ?? 4) >= 4;
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo kỷ vật 3D')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Thêm 3 góc ảnh khuôn mặt',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _doneCount / 3,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$_doneCount/3',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    size: 20,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Dùng ảnh của cùng một người, đủ sáng, nét mặt tự nhiên, không đeo kính hay che mặt.',
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_capabilities == null && _error == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),
            if (_capabilities == null && _error != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _loadCapabilities,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại cấu hình'),
                ),
              ),
            for (final view in _requiredViews) _slot(view),
            if (showBack) _slot('back'),
            const SizedBox(height: 4),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _consent,
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _consent = value ?? false),
              title: const Text(
                'Tôi có quyền sử dụng các ảnh này và đồng ý cho xử lý để tạo mô hình 3D.',
              ),
            ),
            Text(
              'Sau khi dựng xong, bạn có thể chọn mũ hoặc tóc, thêm kính và lưu thiết kế mà không tạo lại khuôn mặt.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_busy) ...[
                Text(_phase),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _phase.startsWith('Tải ảnh') ? _upload : null,
                ),
                const SizedBox(height: 8),
              ],
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: scheme.error)),
                const SizedBox(height: 8),
              ],
              FilledButton(
                onPressed: _canSubmit ? _submit : null,
                child: Text(
                  _busy
                      ? 'Đang gửi bộ ảnh…'
                      : _doneCount < 3
                      ? 'Thêm ${3 - _doneCount} ảnh nữa để tiếp tục'
                      : 'Tạo mô hình xem trước',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ModelProgressScreen extends StatefulWidget {
  const ModelProgressScreen({
    super.key,
    required this.scanId,
    this.jobId,
    this.api,
  });
  final String scanId;
  final String? jobId;
  final ApiClient? api;
  @override
  State<ModelProgressScreen> createState() => _ModelProgressScreenState();
}

class _ModelProgressScreenState extends State<ModelProgressScreen>
    with WidgetsBindingObserver {
  late final ApiClient _api;
  Timer? _timer;
  bool _polling = false, _opening = false, _paused = false;
  String? _jobId, _error;
  String _status = 'queued', _stage = '';
  num? _progress;
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? ApiClient();
    _jobId = widget.jobId;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _timer?.cancel();
    } else {
      unawaited(_poll());
    }
  }

  Future<void> _poll() async {
    if (!mounted || _polling || _opening || _paused) return;
    _timer?.cancel();
    _polling = true;
    try {
      if (_jobId == null) {
        final latest = Map<String, dynamic>.from(
          await _api.get('/api/v1/scans/${widget.scanId}/reconstruction-jobs')
              as Map,
        );
        _jobId = latest['job_id'] as String;
      }
      final job = Map<String, dynamic>.from(
        await _api.get('/api/v1/reconstruction-jobs/$_jobId') as Map,
      );
      requireRealExecution(job);
      if (!mounted) return;
      setState(() {
        _status = (job['status'] as String).toLowerCase();
        _stage = job['stage'] as String? ?? '';
        _progress = job['progress'] as num?;
        _error = null;
      });
      if (_status == 'done' || _status == 'completed') {
        final raw = await _api.get(
          '/api/v1/reconstruction-jobs/$_jobId/outputs',
        );
        if (raw is! List) throw const FormatException('Output list invalid');
        final files = raw
            .whereType<Map>()
            .where((v) => (v['format'] as String? ?? '').toLowerCase() == 'glb')
            .toList();
        if (files.isEmpty) {
          throw const FormatException(
            'Tác vụ đã xong nhưng chưa có model. Bấm Tải lại mô hình.',
          );
        }
        final outputId =
            (files.first['output_id'] ?? files.first['id']) as String;
        if (!mounted) return;
        _opening = true;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CustomizationScreen(
              outputId: outputId,
              api: CustomizationApi(client: _api),
            ),
          ),
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (_status == 'failed' || _status == 'cancelled') {
        setState(
          () => _error =
              job['error_message'] as String? ??
              'Tác vụ đã dừng. Bạn có thể tạo phiên mới hoặc xem lại sau.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ApiException
              ? error.message
              : error is FormatException
              ? error.message
              : 'Chưa cập nhật được tiến trình. Tác vụ vẫn có thể đang chạy.',
        );
      }
    } finally {
      _polling = false;
      if (mounted &&
          !_paused &&
          !_opening &&
          !['done', 'completed', 'failed', 'cancelled'].contains(_status)) {
        _timer = Timer(const Duration(seconds: 4), () => unawaited(_poll()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final failed = ['failed', 'cancelled'].contains(_status),
        done = ['done', 'completed'].contains(_status);
    final stage =
        {
          'downloading': 'Tải ảnh đầu vào',
          'preprocessing': 'Tiền xử lý ảnh',
          'shape_generation': 'Tạo hình khối',
          'texturing': 'Tạo texture',
          'validating': 'Kiểm tra mô hình',
          'exporting': 'Xuất mô hình',
          'uploading': 'Lưu kết quả',
        }[_stage] ??
        (_status == 'queued' ? 'Đang chờ đến lượt' : 'Đang xử lý');
    return Scaffold(
      appBar: AppBar(title: const Text('Tiến trình tạo 3D')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              failed
                  ? 'Tác vụ đã dừng'
                  : done
                  ? 'Đang mở thiết kế'
                  : 'Đang dựng kỷ vật của bạn',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            if (!failed)
              LinearProgressIndicator(
                value: _progress == null
                    ? null
                    : (_progress! / 100).clamp(0, 1).toDouble(),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(stage),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _polling ? null : _poll,
              child: Text(done ? 'Tải lại mô hình' : 'Kiểm tra lại trạng thái'),
            ),
            const Text(
              'Bạn có thể quay về danh sách và mở lại tác vụ. Đừng gửi lại ảnh chỉ vì mất kết nối.',
            ),
          ],
        ),
      ),
    );
  }
}
