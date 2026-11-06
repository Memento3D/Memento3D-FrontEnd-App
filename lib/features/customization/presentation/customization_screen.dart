import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_exception.dart';
import '../data/customization_api.dart';
import 'customization_canvas.dart';
import 'custom_print_checkout_screen.dart';

class CustomizationScreen extends StatefulWidget {
  const CustomizationScreen({
    super.key,
    required this.outputId,
    this.initialScene,
    this.api,
  });
  final String outputId;
  final DesignScene? initialScene;
  final CustomizationApi? api;
  @override
  State<CustomizationScreen> createState() => _CustomizationScreenState();
}

class _CustomizationScreenState extends State<CustomizationScreen> {
  late final CustomizationApi _api;
  DesignScene? _scene;
  DesignDraft? _draft;
  DesignSelection _selection = {}, _applied = {};
  bool _loading = true,
      _busy = true,
      _saving = false,
      _conflict = false,
      _allowPop = false;
  bool _renderReady = false;
  String? _error, _notice;
  int _retry = 0;
  Future<void> _persistence = Future.value();
  String get _key => 'memento3d:unsaved-design:${widget.outputId}';
  bool get _dirty =>
      _draft != null && !mapEquals(_selection, _draft!.selection);
  @override
  void initState() {
    super.initState();
    _api = widget.api ?? CustomizationApi();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final scene = widget.initialScene ?? await _api.scene(widget.outputId);
      var selection = Map<String, String?>.from(scene.draft.selection);
      bool stale = false, recovered = false;
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(_key);
        if (raw != null) {
          final local = jsonDecode(raw) as Map<String, dynamic>;
          final choice = Map<String, String?>.from(local['selection'] as Map);
          if (local['fitResultId'] == scene.fitId &&
              scene.accepts(choice) &&
              scene.draft.editable &&
              !mapEquals(choice, selection)) {
            selection = choice;
            stale = local['revision'] != scene.draft.revision;
            recovered = true;
          }
        }
      } catch (_) {
        /* Optional browser-equivalent local draft cannot replace server authority. */
      }
      if (!mounted) return;
      setState(() {
        _scene = scene;
        _draft = scene.draft;
        _selection = selection;
        _loading = false;
        _busy = true;
        _conflict = stale;
        _notice = recovered
            ? 'Đã khôi phục thay đổi chưa lưu trên thiết bị. Bấm Lưu thiết kế để lưu vào tài khoản.'
            : null;
        _error = stale
            ? 'Bản lưu đã thay đổi. Tải bản đã lưu trước khi ghi lại.'
            : null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error is ApiException
              ? error.message
              : 'Không mở được thiết kế. Hãy thử lại.';
        });
      }
    }
  }

  Future<void> _remember() async {
    final draft = _draft;
    if (draft == null) return;
    final payload = _dirty && !_conflict
        ? jsonEncode({
            'fitResultId': draft.fitId,
            'revision': draft.revision,
            'selection': _selection,
          })
        : null;
    if (_conflict) return;
    _persistence = _persistence.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (payload == null) {
          await prefs.remove(_key);
        } else {
          await prefs.setString(_key, payload);
        }
      } catch (_) {}
    });
    await _persistence;
  }

  Future<DesignScene> _refresh() async {
    final fresh = await _api.scene(widget.outputId);
    if (_scene == null || !_scene!.sameGeometry(fresh)) {
      throw const FormatException('Mô hình đã đổi phiên bản. Hãy mở lại.');
    }
    if (mounted) setState(() => _scene = fresh);
    return fresh;
  }

  void _choose(String slot, String? id) {
    if (_saving || _draft?.editable != true || _selection[slot] == id) return;
    setState(() {
      _selection = {..._selection, slot: id};
      _busy = true;
      _renderReady = false;
      _error = null;
    });
    unawaited(_remember());
  }

  Future<bool> _confirm(String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Thiết kế chưa lưu'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Tiếp tục chỉnh'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _restore() async {
    if (_dirty &&
        !await _confirm('Thay các lựa chọn đang chỉnh bằng bản đã lưu?')) {
      return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final draft = await _api.draft(widget.outputId);
      if (draft.fitId != _scene!.fitId || !_scene!.accepts(draft.selection)) {
        throw const FormatException('Fit đã thay đổi. Hãy mở lại mô hình.');
      }
      if (!mounted) return;
      final changed = !mapEquals(_selection, draft.selection);
      setState(() {
        _draft = draft;
        _selection = Map.from(draft.selection);
        _busy = changed;
        _renderReady = changed ? false : _renderReady;
        _conflict = false;
        _error = null;
        _notice = null;
      });
      await _remember();
    } catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = error is ApiException ? error.message : error.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_busy ||
        !_renderReady ||
        _saving ||
        _conflict ||
        _draft?.editable != true) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final draft = await _api.save(
        widget.outputId,
        _draft!,
        Map.from(_selection),
      );
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _notice = 'Đã lưu thiết kế vào tài khoản.';
      });
      await _remember();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _conflict = error.statusCode == 409;
          _error = _conflict
              ? 'Thiết kế đã thay đổi từ nơi khác. Lựa chọn đang chỉnh vẫn được giữ.'
              : error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Chưa lưu được thiết kế. Lựa chọn vẫn được giữ.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_dirty || _allowPop,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || _allowPop) return;
      if (await _confirm(
            'Rời trang? Thay đổi được giữ tạm trên thiết bị, chưa lưu vào tài khoản.',
          ) &&
          mounted) {
        setState(() => _allowPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.of(context).pop();
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Tùy chỉnh kỷ vật 3D')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _scene == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error ?? 'Chưa mở được thiết kế'),
                  FilledButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thêm dấu ấn riêng',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const Text(
                          'Chọn mũ hoặc tóc, thêm kính và xoay để xem trước.',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _dirty
                              ? 'Chưa lưu thay đổi'
                              : _draft!.exists
                              ? 'Đã lưu thiết kế'
                              : 'Bản mặc định',
                        ),
                      ],
                    ),
                  ),
                  if (_notice != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(_notice!),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          if (_conflict)
                            TextButton(
                              onPressed: _saving ? null : _restore,
                              child: const Text('Tải bản đã lưu'),
                            ),
                          if (!_conflict)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _retry++;
                                  _busy = true;
                                  _error = null;
                                });
                              },
                              child: const Text('Tải lại 3D'),
                            ),
                        ],
                      ),
                    ),
                  CustomizationCanvas(
                    key: ValueKey('${widget.outputId}:$_retry'),
                    scene: _scene!,
                    selection: Map.from(_selection),
                    refresh: _refresh,
                    onBusy: () {},
                    onReady: (value) {
                      if (mounted) {
                        setState(() {
                          _applied = value;
                          _busy = false;
                          _renderReady = true;
                        });
                      }
                    },
                    onError: (message) {
                      if (mounted) {
                        setState(() {
                          _error = message;
                          _busy = false;
                          _renderReady = false;
                          if (_applied.isNotEmpty) {
                            _selection = Map.from(_applied);
                          }
                        });
                      }
                    },
                  ),
                  if (!_draft!.editable)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Thiết kế đang ở chế độ chỉ xem.'),
                    ),
                  for (final group in _scene!.groups) _group(group),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.print_outlined),
                          label: const Text('Đặt sản xuất bản đã lưu'),
                          onPressed:
                              _dirty ||
                                  _busy ||
                                  !_renderReady ||
                                  _saving ||
                                  _conflict ||
                                  _draft?.exists != true ||
                                  _draft?.editable != true
                              ? null
                              : () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => CustomPrintCheckoutScreen(
                                      scene: _scene!,
                                      draft: _draft!,
                                      client: _api.client,
                                    ),
                                  ),
                                ),
                        ),
                        const Text(
                          'Lưu thiết kế trước khi gửi xưởng. Bạn thanh toán sau khi đồng ý báo giá.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: _scene == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving || _busy || (!_dirty && !_conflict)
                            ? null
                            : _restore,
                        child: const Text('Khôi phục'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            _saving ||
                                _busy ||
                                !_renderReady ||
                                _conflict ||
                                _draft?.editable != true ||
                                (!_dirty && _draft!.exists)
                            ? null
                            : _save,
                        child: Text(_saving ? 'Đang lưu…' : 'Lưu thiết kế'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    ),
  );
  Widget _group(Map<String, dynamic> group) {
    final slot = group['id'] as String;
    final assets = _scene!.assets
        .where(
          (asset) => (group['assetVersionIds'] as List).contains(
            asset['assetVersionId'],
          ),
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slot == 'headwear'
                ? 'Kiểu đầu'
                : slot == 'glasses'
                ? 'Mắt kính'
                : slot,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (group['noneAllowed'] == true && group['required'] != true)
                _option(slot, null, 'Không kính', null),
              for (final asset in assets)
                _option(
                  slot,
                  asset['assetVersionId'] as String,
                  asset['name'] as String,
                  asset['thumbnailUrl'] as String,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _option(String slot, String? id, String name, String? thumbnail) =>
      Semantics(
        selected: _selection[slot] == id,
        button: true,
        label: name,
        child: SizedBox(
          width: 145,
          child: Card(
            color: _selection[slot] == id
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: InkWell(
              onTap: _saving || _draft?.editable != true
                  ? null
                  : () => _choose(slot, id),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: [
                    if (thumbnail != null)
                      Image.network(
                        thumbnail,
                        height: 76,
                        width: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 76,
                          child: Icon(Icons.image_not_supported_outlined),
                        ),
                      )
                    else
                      const SizedBox(
                        height: 76,
                        child: Icon(Icons.block, size: 30),
                      ),
                    Text(name, textAlign: TextAlign.center),
                    if (_selection[slot] == id)
                      Text(_busy ? 'Đang tải…' : 'Đang chọn'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
