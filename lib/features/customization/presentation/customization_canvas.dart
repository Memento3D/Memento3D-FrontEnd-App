import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../model_viewer/data/services/model_download_service.dart';
import '../../model_viewer/presentation/controllers/model_viewer_controller.dart';
import '../../model_viewer/presentation/widgets/model_viewer_webview.dart';
import '../data/customization_api.dart';

class CustomizationCanvas extends StatefulWidget {
  const CustomizationCanvas({
    super.key,
    required this.scene,
    required this.selection,
    required this.refresh,
    required this.onReady,
    required this.onError,
    required this.onBusy,
  });
  final DesignScene scene;
  final DesignSelection selection;
  final Future<DesignScene> Function() refresh;
  final ValueChanged<DesignSelection> onReady;
  final ValueChanged<String> onError;
  final VoidCallback onBusy;
  @override
  State<CustomizationCanvas> createState() => _CustomizationCanvasState();
}

class _CustomizationCanvasState extends State<CustomizationCanvas> {
  late final ModelViewerController _viewer;
  final _downloads = ModelDownloadService();
  final _cache = <String, Future<File>>{};
  final _owned = <File>[];
  Map<String, dynamic>? _bridgeScene;
  DesignSelection _submitted = {};
  int _generation = 0, _bridgeGeneration = -1;
  String? _reported;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _viewer = ModelViewerController(timeout: const Duration(minutes: 2))
      ..addListener(_receive);
    unawaited(_prepare());
  }

  @override
  void didUpdateWidget(covariant CustomizationCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (jsonEncode(widget.selection) != jsonEncode(oldWidget.selection)) {
      unawaited(_prepare());
    }
  }

  Future<File> _file(Map<String, dynamic> asset, {String? id}) {
    final key = '${id ?? 'base'}:${asset['sha256']}';
    return _cache.putIfAbsent(key, () async {
      try {
        late File file;
        try {
          file = await _downloads.downloadGlb(
            url: asset['url'] as String,
            onProgress: (_, _) {},
          );
        } on ApiException catch (error) {
          if (error.statusCode != 401 && error.statusCode != 403) rethrow;
          final fresh = await widget.refresh();
          if (!widget.scene.sameGeometry(fresh)) {
            throw const FormatException(
              'Scene đã thay đổi. Hãy mở lại thiết kế.',
            );
          }
          final source = id == null
              ? fresh.base
              : fresh.assets.firstWhere((item) => item['assetVersionId'] == id);
          file = await _downloads.downloadGlb(
            url: source['url'] as String,
            onProgress: (_, _) {},
          );
        }
        if (!mounted) {
          await _remove(file);
          throw const FormatException('Viewer closed');
        }
        _owned.add(file);
        return file;
      } catch (_) {
        scheduleMicrotask(() => _cache.remove(key));
        rethrow;
      }
    });
  }

  Future<void> _prepare() async {
    final generation = ++_generation;
    final selected = Map<String, String?>.from(widget.selection);
    setState(() => _loading = true);
    try {
      final scene =
          jsonDecode(jsonEncode(widget.scene.json)) as Map<String, dynamic>;
      final base = scene['baseModel'] as Map<String, dynamic>;
      base['url'] = (await _file(base)).uri.toString();
      for (final raw in scene['assets'] as List) {
        final asset = raw as Map<String, dynamic>;
        if (selected.containsValue(asset['assetVersionId'])) {
          asset['url'] = (await _file(
            asset,
            id: asset['assetVersionId'] as String,
          )).uri.toString();
        }
      }
      if (!mounted || generation != _generation) return;
      setState(() {
        _bridgeScene = scene;
        _submitted = selected;
        _bridgeGeneration = generation;
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() => _loading = false);
      widget.onError(
        error is ApiException
            ? error.message
            : 'Không tải được mô hình hoặc phụ kiện. Vui lòng thử lại.',
      );
    }
  }

  void _receive() {
    if (!mounted ||
        _bridgeGeneration != _generation ||
        (_viewer.state.requestId != null &&
            _reported == _viewer.state.requestId)) {
      return;
    }
    if (_viewer.status == ModelViewerStatus.loaded) {
      _reported = _viewer.state.requestId;
      setState(() => _loading = false);
      widget.onReady(Map.from(_submitted));
    } else if (_viewer.status == ModelViewerStatus.loadFailure ||
        _viewer.status == ModelViewerStatus.initializationError) {
      _reported = _viewer.state.requestId;
      setState(() => _loading = false);
      widget.onError('Không thể hiển thị 3D. Hãy thử tải lại.');
    }
  }

  Future<void> _remove(File file) async {
    try {
      await file.delete();
      await file.parent.delete();
    } catch (_) {}
  }

  @override
  void dispose() {
    _generation++;
    _downloads.dispose();
    _viewer.removeListener(_receive);
    _viewer.dispose();
    for (final file in _owned) {
      unawaited(_remove(file));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 420,
    child: Stack(
      children: [
        Positioned.fill(
          child: _bridgeScene == null
              ? const ColoredBox(color: Color(0xFF171321))
              : ModelViewerWebView(
                  controller: _viewer,
                  modelUrl: null,
                  customization: _bridgeScene,
                  selection: _submitted,
                ),
        ),
        if (_loading)
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Đang tải mô hình và phụ kiện…')),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Wrap(
            spacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: () => _viewer.focusFace(),
                child: const Text('Xem khuôn mặt'),
              ),
              FilledButton.tonal(
                onPressed: () => _viewer.resetView(),
                child: const Text('Toàn thân'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
