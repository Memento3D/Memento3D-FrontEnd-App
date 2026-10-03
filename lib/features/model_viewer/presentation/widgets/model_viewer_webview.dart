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
  });

  final ModelViewerController controller;
  final String? modelUrl;

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
    if (oldWidget.modelUrl != widget.modelUrl && _ready) {
      unawaited(_sendModel());
    }
  }

  Future<void> _sendModel() async {
    final message = widget.controller.loadModel(widget.modelUrl);
    if (message == null || !mounted) return;
    final command = jsonDecode(message) as Map<String, dynamic>;
    final id = command['requestId'] as String;
    try {
      if (widget.modelUrl != null) {
        command['modelUrl'] = _server.resolveModelUrl(widget.modelUrl!, id);
      }
    } on FormatException {
      // Invalidate the old JS load even when the replacement URL is rejected.
      command['modelUrl'] = null;
      widget.controller.failLoad(id, 'unsupportedUrl');
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
