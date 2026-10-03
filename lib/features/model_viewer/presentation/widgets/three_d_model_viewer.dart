import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../controllers/model_viewer_controller.dart';
import 'model_viewer_webview.dart';
import 'model_viewer_toolbar.dart';

/// Embedded Three.js viewer for self-contained GLBs. Host facts stay outside.
class ThreeDModelViewer extends StatefulWidget {
  const ThreeDModelViewer({
    super.key,
    required this.modelUrl,
    this.viewportHeight,
    this.enableDiagnostics = false,
  });

  /// HTTPS URL or asset:///assets/...glb; null clears the current model.
  final String? modelUrl;

  /// A bounded viewport inside a scrolling host. Null fills bounded parent space.
  final double? viewportHeight;

  /// Optional development instrumentation; ignored in release builds.
  final bool enableDiagnostics;

  @override
  State<ThreeDModelViewer> createState() => _ThreeDModelViewerState();
}

class _ThreeDModelViewerState extends State<ThreeDModelViewer> {
  late final _controller = ModelViewerController(
    enableDiagnostics: widget.enableDiagnostics,
  );

  @override
  void didUpdateWidget(covariant ThreeDModelViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enableDiagnostics != widget.enableDiagnostics) {
      _controller.setDiagnosticsEnabled(widget.enableDiagnostics);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final viewport = Stack(
      fit: StackFit.expand,
      children: [
        ModelViewerWebView(controller: _controller, modelUrl: widget.modelUrl),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: ModelViewerToolbar(controller: _controller, showHint: false),
        ),
        Positioned(
          bottom: 16,
          left: 48,
          right: 48,
          child: IgnorePointer(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface
                      .withValues(alpha: .88),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.threesixty, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        strings.modelViewerInteractionHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 88,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.status == ModelViewerStatus.loaded) {
                  return const SizedBox.shrink();
                }
                return Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface
                          .withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_controller.status ==
                            ModelViewerStatus.loading) ...[
                          LinearProgressIndicator(
                            value: _controller.state.progress,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(switch (_controller.status) {
                          ModelViewerStatus.initializing =>
                            strings.modelViewerInitializing,
                          ModelViewerStatus.ready => strings.modelViewerReady,
                          ModelViewerStatus.initializationError =>
                            strings.modelViewerInitializationError,
                          ModelViewerStatus.loading =>
                            strings.modelViewerLoading,
                          ModelViewerStatus.loaded => strings.modelViewerLoaded,
                          ModelViewerStatus.loadFailure =>
                            strings.modelViewerLoadError,
                        }, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 80,
          child: IgnorePointer(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (!_controller.diagnosticsEnabled ||
                    _controller.status != ModelViewerStatus.loaded) {
                  return const SizedBox.shrink();
                }
                final stats = _controller.statistics;
                final sample = _controller.performanceSample;
                String fps(double? value) => value?.toStringAsFixed(1) ?? '—';
                return Container(
                  key: const ValueKey('viewer-diagnostics'),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'DEV · WebView frame cadence\n'
                    'Triangles ${stats?.triangleCount ?? '—'} · Vertices ${stats?.vertexCount ?? '—'} · Meshes ${stats?.meshCount ?? '—'}\n'
                    'FPS ${fps(sample?.fps)} · Avg ${fps(sample?.averageFps)} · Min ${fps(sample?.minimumFps)}\n'
                    '${sample?.frameCount ?? 0} frames · ${((sample?.elapsedMs ?? 0) / 1000).toStringAsFixed(1)} s active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
    return widget.viewportHeight == null
        ? viewport
        : SizedBox(height: widget.viewportHeight, child: viewport);
  }
}
