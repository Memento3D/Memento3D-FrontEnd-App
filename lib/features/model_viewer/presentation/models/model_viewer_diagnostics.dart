import 'package:flutter/foundation.dart';

bool _count(Object? value) => value is int && value >= 0;
bool _finite(Object? value) => value is num && value.isFinite && value >= 0;

@immutable
class ModelGeometryStatistics {
  const ModelGeometryStatistics({
    required this.triangleCount,
    required this.vertexCount,
    required this.meshCount,
  });
  final int triangleCount;
  final int vertexCount;
  final int meshCount;

  static ModelGeometryStatistics? fromMessage(Map<String, dynamic> value) {
    if (!_count(value['triangleCount']) ||
        !_count(value['vertexCount']) ||
        !_count(value['meshCount'])) {
      return null;
    }
    return ModelGeometryStatistics(
      triangleCount: value['triangleCount'] as int,
      vertexCount: value['vertexCount'] as int,
      meshCount: value['meshCount'] as int,
    );
  }
}

/// Development frame cadence, not GPU timing or an acceptance verdict.
@immutable
class ModelPerformanceSample {
  const ModelPerformanceSample({
    required this.fps,
    required this.averageFps,
    required this.minimumFps,
    required this.frameCount,
    required this.elapsedMs,
    required this.windowFrameCount,
    required this.windowElapsedMs,
  });
  final double fps;
  final double averageFps;

  /// Lowest complete reporting-window FPS in this model's measurement session.
  final double minimumFps;
  final int frameCount;
  final double elapsedMs;
  final int windowFrameCount;
  final double windowElapsedMs;

  static ModelPerformanceSample? fromMessage(Map<String, dynamic> value) {
    for (final field in [
      'fps',
      'averageFps',
      'minimumFps',
      'elapsedMs',
      'windowElapsedMs',
    ]) {
      if (!_finite(value[field])) return null;
    }
    if (!_count(value['frameCount']) || !_count(value['windowFrameCount'])) {
      return null;
    }
    final frames = value['frameCount'] as int;
    final windowFrames = value['windowFrameCount'] as int;
    final elapsed = (value['elapsedMs'] as num).toDouble();
    final windowElapsed = (value['windowElapsedMs'] as num).toDouble();
    if (frames == 0 ||
        windowFrames == 0 ||
        windowFrames > frames ||
        elapsed <= 0 ||
        windowElapsed < 1000 ||
        windowElapsed > elapsed) {
      return null;
    }
    return ModelPerformanceSample(
      fps: (value['fps'] as num).toDouble(),
      averageFps: (value['averageFps'] as num).toDouble(),
      minimumFps: (value['minimumFps'] as num).toDouble(),
      frameCount: frames,
      elapsedMs: elapsed,
      windowFrameCount: windowFrames,
      windowElapsedMs: windowElapsed,
    );
  }
}
