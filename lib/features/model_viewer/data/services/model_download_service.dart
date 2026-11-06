import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/network/api_config.dart';
import '../../../auth/data/services/auth_storage.dart';
import '../../../../core/network/api_exception.dart';

/// Downloads the real GLB asset so the viewer receives actual model data.
class ModelDownloadService {
  ModelDownloadService({http.Client? client})
    : _httpClient = client ?? http.Client();

  final http.Client _httpClient;

  void dispose() => _httpClient.close();

  Future<File> downloadGlb({
    required String url,
    required void Function(int loadedBytes, int? totalBytes) onProgress,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw ApiException(
        statusCode: 400,
        errorCode: 'ERR-017',
        message: 'The model URL is not valid.',
      );
    }
    final headers = <String, String>{};
    final apiBase = Uri.tryParse(ApiConfig.baseUrl);
    final isBackendHost =
        apiBase != null && uri.host == apiBase.host && uri.port == apiBase.port;
    if (isBackendHost) {
      final token = await AuthStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    final request = http.Request('GET', uri)..headers.addAll(headers);
    // A signed storage URL is already the destination; do not forward auth.
    request.followRedirects = false;
    late http.StreamedResponse response;
    try {
      response = await _httpClient.send(request).timeout(ApiConfig.timeout);
    } on SocketException {
      throw ApiException(
        statusCode: 0,
        errorCode: 'ERR-017',
        message: 'Could not connect to download the model.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.stream.drain<void>();
      throw ApiException(
        statusCode: response.statusCode,
        errorCode: 'ERR-017',
        message: 'The model download failed (HTTP ${response.statusCode}).',
      );
    }
    final total = int.tryParse(
      response.headers['content-length'] ??
          response.headers['Content-Length'] ??
          '',
    );
    final directory = await Directory.systemTemp.createTemp('memento3d_model_');
    final file = File('${directory.path}/model.glb');
    final sink = file.openWrite();
    var loaded = 0;
    var complete = false;
    try {
      await for (final chunk in response.stream.timeout(
        const Duration(seconds: 30),
      )) {
        sink.add(chunk);
        loaded += chunk.length;
        onProgress(loaded, total);
      }
      await sink.flush();
      if (total != null && loaded != total) {
        throw const FormatException('Incomplete GLB download');
      }
      final reader = await file.open();
      try {
        final header = await reader.read(12);
        if (header.length != 12 ||
            header[0] != 0x67 ||
            header[1] != 0x6c ||
            header[2] != 0x54 ||
            header[3] != 0x46) {
          throw const FormatException('The downloaded file is not a GLB model');
        }
      } finally {
        await reader.close();
      }
      complete = true;
    } finally {
      await sink.close();
      if (!complete) {
        try {
          await file.delete();
          await directory.delete();
        } catch (_) {}
      }
    }
    return file;
  }
}
