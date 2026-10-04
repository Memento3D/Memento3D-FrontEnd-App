import 'dart:async';

/// Minimal job WebSocket abstraction so tests (and non-IO platforms) can
/// inject a fake.
abstract class JobSocket {
  Stream<String> get messages;
  Future<void> close();
}

typedef JobSocketFactory = Future<JobSocket> Function(String scanId);
