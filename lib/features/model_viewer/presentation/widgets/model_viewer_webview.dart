import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../controllers/model_viewer_controller.dart';
import '../services/viewer_asset_server.dart';

/// Owns the platform view. Only trusted, bundled content receives the channel.
class ModelViewerWebView extends StatefulWidget {
  const ModelViewerWebView({
    super.key,
    required this.controller,
    required this.modelUrl,
    this.customization,
    this.selection,
  });

  final ModelViewerController controller;
  final String? modelUrl;
  final Map<String, dynamic>? customization;
  final Map<String, String?>? selection;

  @override
  State<ModelViewerWebView> createState() => _ModelViewerWebViewState();
}

class _ModelViewerWebViewState extends State<ModelViewerWebView> {
  final _server = ViewerAssetServer();
  WebViewController? _webView;
  bool _ready = false;
  late final StreamSubscription<String> _commands;

  Future<void> _sendControl(String message) async {
    if (!mounted || !_ready) return;
    final command = jsonDecode(message) as Map<String, dynamic>;
    try {
      await _webView!.runJavaScript(
        'window.receiveModelViewerCommand(${jsonEncode(command)});',
      );
    } catch (_) {
      if (mounted) {
        widget.controller.failCommand(command['requestId'] as String);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ModelViewerWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.modelUrl != widget.modelUrl ||
            oldWidget.customization != widget.customization ||
            oldWidget.selection != widget.selection) &&
        _ready) {
      unawaited(_sendModel());
    }
  }

  Future<void> _sendModel() async {
    final message = widget.customization != null
        ? widget.controller.loadCustomization(
            widget.customization!,
            widget.selection!,
          )
        : widget.controller.loadModel(widget.modelUrl);
    if (message == null || !mounted) return;
    final command = jsonDecode(message) as Map<String, dynamic>;
    final id = command['requestId'] as String;
    try {
      if (widget.customization != null) {
        final scene =
            jsonDecode(jsonEncode(command['scene'])) as Map<String, dynamic>;
        final base = scene['baseModel'] as Map<String, dynamic>;
        base['url'] = _server.resolveModelUrl(
          base['url'] as String,
          'custom-base',
          retainExisting: true,
        );
        for (final item in scene['assets'] as List) {
          final asset = item as Map<String, dynamic>;
          if (widget.selection!.containsValue(asset['assetVersionId'])) {
            asset['url'] = _server.resolveModelUrl(
              asset['url'] as String,
              'custom-${asset['assetVersionId']}',
              retainExisting: true,
            );
          }
        }
        command['scene'] = scene;
      }
      if (widget.modelUrl != null) {
        command['modelUrl'] = _server.resolveModelUrl(widget.modelUrl!, id);
      }
    } on FormatException {
      // Invalidate the old JS load even when the replacement URL is rejected.
      command['modelUrl'] = null;
      widget.controller.failLoad(id, 'unsupportedUrl');
      if (widget.customization != null) return;
    }
    try {
      await _webView!.runJavaScript(
        'window.receiveModelViewerCommand(${jsonEncode(command)});',
      );
    } catch (_) {
      if (mounted) widget.controller.failLoad(id, 'bridgeFailed');
    }
  }

  @override
  void initState() {
    super.initState();
    _commands = widget.controller.commands.listen(
      (message) => unawaited(_sendControl(message)),
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await _server.start();
      if (!mounted) return;
      final webView = WebViewController();
      _webView = webView;
      await webView.setJavaScriptMode(JavaScriptMode.unrestricted);
      await webView.setBackgroundColor(const Color(0xFFFDF8FF));
      await webView.enableZoom(false);
      await webView.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            return request.url == _server.page.toString()
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              widget.controller.failInitialization();
            }
          },
        ),
      );
      await webView.addJavaScriptChannel(
        'ModelViewerBridge',
        onMessageReceived: (message) {
          if (!mounted) return;
          widget.controller.receiveMessage(message.message);
          if (!_ready && widget.controller.status == ModelViewerStatus.ready) {
            _ready = true;
            unawaited(_sendModel());
          }
        },
      );
      if (!mounted) {
        await _release(webView);
        return;
      }
      setState(() {});
      await webView.loadRequest(_server.page);
    } catch (_) {
      if (mounted) widget.controller.failInitialization();
    }
  }

  Future<void> _release(WebViewController webView) async {
    try {
      await webView.runJavaScript('window.disposeModelViewer?.();');
    } catch (_) {
      // The platform view may already have been removed.
    }
    try {
      await webView.removeJavaScriptChannel('ModelViewerBridge');
    } catch (_) {
      // webview_flutter owns native platform-view destruction.
    }
  }

  @override
  void dispose() {
    unawaited(_commands.cancel());
    final webView = _webView;
    if (webView != null) unawaited(_release(webView));
    unawaited(_server.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _webView == null
      ? const SizedBox.expand()
      : WebViewWidget(
          controller: _webView!,
          // Claim gestures only within the viewport; the host scrolls outside it.
          gestureRecognizers: {
            Factory<EagerGestureRecognizer>(EagerGestureRecognizer.new),
          },
        );
}
