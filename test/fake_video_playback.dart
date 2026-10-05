import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import 'package:memento3d_frontend_app/screens/video_playback.dart';

class FakeVideoPlayback implements VideoPlayback {
  final _notifier = ValueNotifier(
    const VideoPlayerValue(duration: Duration.zero),
  );
  Duration duration = const Duration(seconds: 12);
  Size size = const Size(1920, 1080);
  Completer<void>? initializeGate, playGate, disposeGate;
  bool failDispose = false;
  bool failNextPause = false;
  final List<VoidCallback> registeredListeners = [];
  bool failInitialization = false, failPlay = false, disposed = false;
  int initializes = 0, plays = 0, pauses = 0, disposals = 0;
  final List<Duration> seeks = [];
  @override
  VideoPlayerValue get value => _notifier.value;
  void update(VideoPlayerValue value) => _notifier.value = value;
  @override
  void addListener(VoidCallback listener) {
    registeredListeners.add(listener);
    _notifier.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) =>
      _notifier.removeListener(listener);
  @override
  Future<void> initialize() async {
    initializes++;
    if (initializeGate != null) await initializeGate!.future;
    if (failInitialization) throw StateError('Decoder failure');
    if (!disposed) {
      update(
        VideoPlayerValue(duration: duration, size: size, isInitialized: true),
      );
    }
  }

  @override
  Future<void> play() async {
    plays++;
    if (playGate != null) await playGate!.future;
    if (failPlay) throw StateError('Playback failure');
    if (!disposed) update(value.copyWith(isPlaying: true));
  }

  @override
  Future<void> pause() async {
    pauses++;
    if (failNextPause) {
      failNextPause = false;
      throw StateError('Pause failure');
    }
    if (!disposed) update(value.copyWith(isPlaying: false));
  }

  @override
  Future<void> seekTo(Duration position) async {
    seeks.add(position);
    if (!disposed) {
      update(value.copyWith(position: position, isCompleted: false));
    }
  }

  @override
  Widget buildSurface() => const ColoredBox(
    key: Key('real-video-surface-seam'),
    color: Color(0xFF000000),
  );
  @override
  Future<void> dispose() async {
    disposals++;
    if (disposeGate != null) await disposeGate!.future;
    if (failDispose) throw StateError('Disposal failure');
    disposed = true;
    _notifier.dispose();
  }
}
