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
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        loaded += chunk.length;
        onProgress(loaded, total);
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    return file;
  }
}
