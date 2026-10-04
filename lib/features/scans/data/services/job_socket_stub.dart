import 'job_socket_base.dart';

/// Fallback used on platforms where dart:io WebSocket is unavailable
/// (e.g. Flutter Web). Failing fast makes the polling fallback kick in.
Future<JobSocket> connectJobSocket(String scanId) {
  return Future<JobSocket>.error(
    UnsupportedError('WebSocket not supported on this platform'),
  );
}
