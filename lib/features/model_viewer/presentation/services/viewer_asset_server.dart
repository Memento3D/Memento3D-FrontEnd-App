import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';

/// Loopback only; no filesystem paths, listings, or proxying.
class ViewerAssetServer {
  ViewerAssetServer({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;
  final AssetBundle _bundle;
  HttpServer? _server;
  bool _closed = false;
  final String _token = List.generate(
    24,
    (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  final Map<String, String> _models = {};
  final Map<String, String> _localFiles = {};
  static const _runtime = {
    'index.html': 'text/html; charset=utf-8',
    'viewer.bundle.js': 'text/javascript; charset=utf-8',
    'viewer.css': 'text/css; charset=utf-8',
  };
  Uri get page =>
      Uri.parse('http://127.0.0.1:${_server!.port}/$_token/index.html');

  Future<void> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (_closed) {
      await server.close(force: true);
      return;
    }
    _server = server;
    server.listen(_serve);
  }

  /// Public modelUrl accepts HTTPS, asset:///assets/...glb, or a downloaded
  /// file:// GLB inside the system temp directory.
  String resolveModelUrl(String modelUrl, String requestId) {
    final uri = Uri.tryParse(modelUrl);
    if (uri == null) throw const FormatException('Invalid model URL');
    if (uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty) {
      return uri.toString();
    }
    if (uri.scheme == 'file') {
      final path = uri.toFilePath();
      final tempRoot = Directory.systemTemp.path;
      if (!path.startsWith(tempRoot) || !path.endsWith('.glb')) {
        throw const FormatException('Unsupported model URL');
      }
      _models.clear();
      _localFiles
        ..clear()
        ..['model-$requestId.glb'] = path;
      return page.resolve('model-$requestId.glb').toString();
    }
    if (uri.scheme != 'asset' ||
        uri.host.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException('Unsupported model URL');
    }
    final key = uri.path.replaceFirst(RegExp(r'^/'), '');
    if (!key.startsWith('assets/') ||
        !key.endsWith('.glb') ||
        key.contains('..') ||
        key.contains('\\')) {
      throw const FormatException('Invalid asset key');
    }
    _models.clear();
    _localFiles.clear();
    final name = 'model-$requestId.glb';
    _models[name] = key;
    return page.resolve(name).toString();
  }

  Future<void> _serve(HttpRequest request) async {
    try {
      final segments = request.uri.pathSegments;
      if (request.headers.value(HttpHeaders.hostHeader) != page.authority ||
          request.method != 'GET' ||
          segments.length != 2 ||
          segments.first != _token) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      final name = segments.last;
      final runtimeType = _runtime[name];
      final localPath = _localFiles[name];
      if (localPath != null) {
        final bytes = await File(localPath).readAsBytes();
        request.response.headers.set(
          HttpHeaders.contentTypeHeader,
          'model/gltf-binary',
        );
        request.response.headers.set(
          HttpHeaders.cacheControlHeader,
          'no-store',
        );
        request.response.headers.set('X-Content-Type-Options', 'nosniff');
        request.response.contentLength = bytes.length;
        request.response.add(bytes);
        return;
      }
      final key = runtimeType != null
          ? 'assets/model_viewer/$name'
          : _models[name];
      if (key == null) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }
      final data = await _bundle.load(key);
      request.response.headers.set(
        HttpHeaders.contentTypeHeader,
        runtimeType ?? 'model/gltf-binary',
      );
      request.response.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      request.response.headers.set('X-Content-Type-Options', 'nosniff');
      request.response.contentLength = data.lengthInBytes;
      request.response.add(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      );
    } catch (_) {
      request.response.statusCode = HttpStatus.notFound;
    } finally {
      try {
        await request.response.close();
      } catch (_) {
        /* Client closed. */
      }
    }
  }

  Future<void> close() async {
    _closed = true;
    _models.clear();
    await _server?.close(force: true);
  }
}
