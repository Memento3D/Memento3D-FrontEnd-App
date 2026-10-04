// WebSocket is available on native platforms; web falls back to polling.
export 'job_socket_base.dart';
export 'job_socket_stub.dart'
    if (dart.library.io) 'job_socket_io.dart';
