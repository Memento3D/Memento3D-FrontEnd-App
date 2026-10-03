import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/model_viewer_diagnostics.dart';

enum ModelViewerStatus {
  initializing,
  ready,
  initializationError,
  loading,
  loaded,
  loadFailure,
}

enum DisplayMode { shaded, wireframe }

@immutable
class ModelViewerState {
  const ModelViewerState(
    this.status, {
    this.requestId,
    this.loadedBytes = 0,
    this.totalBytes,
    this.errorCode,
  });
  final ModelViewerStatus status;
  final String? requestId;
  final int loadedBytes;
  final int? totalBytes;
  final String? errorCode;
  double? get progress =>
      totalBytes == null ? null : (loadedBytes / totalBytes!).clamp(0, 1);
}

class ModelViewerController extends ChangeNotifier {
  ModelViewerController({
    Duration timeout = const Duration(seconds: 20),
    bool enableDiagnostics = false,
  }) {
    _diagnosticsEnabled = enableDiagnostics && !kReleaseMode;
    _timeout = Timer(timeout, failInitialization);
  }
  ModelViewerState _state = const ModelViewerState(
    ModelViewerStatus.initializing,
  );
  ModelViewerState get state => _state;
  ModelViewerStatus get status => _state.status;
  late final Timer _timeout;
  bool _disposed = false;
  bool _ready = false;
  int _sequence = 0;
  final _commands = StreamController<String>.broadcast(sync: true);
  Stream<String> get commands => _commands.stream;
  DisplayMode _displayMode = DisplayMode.shaded;
  DisplayMode get displayMode => _displayMode;
  bool _gridVisible = false;
  bool get gridVisible => _gridVisible;
  bool get controlsEnabled => !_disposed && status == ModelViewerStatus.loaded;
  bool _diagnosticsEnabled = false;
  bool get diagnosticsEnabled => _diagnosticsEnabled;
  ModelGeometryStatistics? _statistics;
  ModelGeometryStatistics? get statistics => _statistics;
  ModelPerformanceSample? _performanceSample;
  ModelPerformanceSample? get performanceSample => _performanceSample;

  /// Opt-in only in debug/profile; a release build cannot enable diagnostics.
  void setDiagnosticsEnabled(bool enabled) {
    enabled = enabled && !kReleaseMode;
    if (_disposed || enabled == _diagnosticsEnabled) return;
    _diagnosticsEnabled = enabled;
    _statistics = null;
    _performanceSample = null;
    _command('setDiagnostics', {'version': 1, 'enabled': enabled});
    notifyListeners();
  }

  void _command(String type, [Map<String, Object?> values = const {}]) {
    if (!controlsEnabled) return;
    _commands.add(
      jsonEncode({'type': type, 'requestId': state.requestId, ...values}),
    );
  }

  void setDisplayMode(DisplayMode mode) {
    if (!controlsEnabled || mode == _displayMode) return;
    _displayMode = mode;
    _command('setDisplayMode', {'mode': mode.name});
    notifyListeners();
  }

  void setGridVisible(bool visible) {
    if (!controlsEnabled || visible == _gridVisible) return;
    _gridVisible = visible;
    _command('setGridVisible', {'visible': visible});
    notifyListeners();
  }

  void resetView() => _command('resetView');

  void failCommand(String requestId) {
    if (!controlsEnabled || requestId != state.requestId) return;
    _set(
      ModelViewerState(
        ModelViewerStatus.loadFailure,
        requestId: requestId,
        errorCode: 'bridgeFailed',
      ),
    );
  }

  void _set(ModelViewerState state) {
    if (_disposed) return;
    if (state.status != ModelViewerStatus.loaded) {
      _statistics = null;
      _performanceSample = null;
    }
    _state = state;
    notifyListeners();
  }

  String? loadModel(String? modelUrl) {
    if (_disposed || !_ready) return null;
    final id = '${++_sequence}';
    _set(
      ModelViewerState(
        modelUrl == null ? ModelViewerStatus.ready : ModelViewerStatus.loading,
        requestId: id,
      ),
    );
    return jsonEncode({
      'type': 'loadModel',
      'requestId': id,
      'modelUrl': modelUrl,
    });
  }

  void receiveMessage(String message) {
    if (_disposed) return;
    try {
      final value = jsonDecode(message);
      if (value is! Map<String, dynamic>) return;
      if (value['type'] == 'viewerReady') {
        if (status != ModelViewerStatus.initializing ||
            value['version'] is! int ||
            value['version'] != 1) {
          return;
        }
        _timeout.cancel();
        _ready = true;
        _set(const ModelViewerState(ModelViewerStatus.ready));
        return;
      }
      if (value['type'] == 'modelStatistics' ||
          value['type'] == 'performanceSample') {
        if (!_diagnosticsEnabled ||
            status != ModelViewerStatus.loaded ||
            value['requestId'] != state.requestId ||
            value['version'] is! int ||
            value['version'] != 1) {
          return;
        }
        if (value['type'] == 'modelStatistics') {
          final statistics = ModelGeometryStatistics.fromMessage(value);
          if (statistics == null) return;
          _statistics = statistics;
        } else {
          final sample = ModelPerformanceSample.fromMessage(value);
          if (sample == null ||
              (_performanceSample != null &&
                  sample.frameCount <= _performanceSample!.frameCount)) {
            return;
          }
          _performanceSample = sample;
        }
        debugPrint('[viewer diagnostics] ${jsonEncode(value)}');
        notifyListeners();
        return;
      }
      if (status != ModelViewerStatus.loading ||
          value['requestId'] != state.requestId) {
        return;
      }
      switch (value['type']) {
        case 'loadingProgress':
          final loaded = value['loadedBytes'];
          final total = value['totalBytes'];
          if (loaded is! int ||
              loaded < 0 ||
              (total != null &&
                  (total is! int || total <= 0 || loaded > total))) {
            return;
          }
          _set(
            ModelViewerState(
              ModelViewerStatus.loading,
              requestId: state.requestId,
              loadedBytes: loaded,
              totalBytes: total as int?,
            ),
          );
        case 'modelLoaded':
          _set(
            ModelViewerState(
              ModelViewerStatus.loaded,
              requestId: state.requestId,
            ),
          );
          // Reapply retained preferences after every successful replacement.
          _command('setDisplayMode', {'mode': _displayMode.name});
          _command('setGridVisible', {'visible': _gridVisible});
          if (_diagnosticsEnabled) {
            _command('setDiagnostics', {'version': 1, 'enabled': true});
          }
        case 'loadError':
          final code = value['code'];
          if (code is! String) return;
          failLoad(state.requestId!, code);
      }
    } on FormatException {
      // Ignore malformed/unrecognized bridge data.
    }
  }

  void failLoad(String requestId, String code) {
    if (_disposed ||
        requestId != state.requestId ||
        status != ModelViewerStatus.loading) {
      return;
    }
    const known = {
      'invalidCommand',
      'unsupportedUrl',
      'resourceLoadFailed',
      'parseFailed',
      'unsupportedExtension',
      'invalidBounds',
      'renderFailed',
      'bridgeFailed',
    };
    _set(
      ModelViewerState(
        ModelViewerStatus.loadFailure,
        requestId: requestId,
        errorCode: known.contains(code) ? code : 'resourceLoadFailed',
      ),
    );
  }

  void failInitialization() {
    if (_disposed || status != ModelViewerStatus.initializing) return;
    _timeout.cancel();
    _set(const ModelViewerState(ModelViewerStatus.initializationError));
  }

  @override
  void dispose() {
    _disposed = true;
    _timeout.cancel();
    unawaited(_commands.close());
    super.dispose();
  }
}
