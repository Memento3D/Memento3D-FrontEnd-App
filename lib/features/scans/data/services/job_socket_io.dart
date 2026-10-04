import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../../../core/network/api_config.dart';
import '../../../../features/auth/data/services/auth_storage.dart';
import 'job_socket_base.dart';

class _IoJobSocket implements JobSocket {
  final WebSocket _socket;
  final _controller = StreamController<String>.broadcast();
  StreamSubscription? _subscription;

  _IoJobSocket(this._socket) {
    _subscription = _socket.listen(
      (data) => _controller.add(data is String ? data : jsonEncode(data)),
      onError: _controller.addError,
      onDone: _controller.close,
    );
  }

  @override
  Stream<String> get messages => _controller.stream;

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _socket.close().catchError((_) {});
    await _controller.close().catchError((_) {});
  }
}

/// Builds the WebSocket endpoint for a job and connects.
Future<JobSocket> connectJobSocket(String scanId) async {
  final base = ApiConfig.baseUrl;
  final wsBase = base.startsWith('https')
      ? base.replaceFirst('https', 'wss')
      : base.replaceFirst('http', 'ws');
  final token = await AuthStorage.getToken();
  final headers = <String, dynamic>{};
  if (token != null && token.isNotEmpty) {
    headers['Authorization'] = 'Bearer $token';
  }
  final uri = Uri.parse('$wsBase/api/v1/ws/jobs/$scanId');
  final socket = await WebSocket.connect(
    uri.toString(),
    headers: headers,
  ).timeout(ApiConfig.timeout);
  return _IoJobSocket(socket);
}
