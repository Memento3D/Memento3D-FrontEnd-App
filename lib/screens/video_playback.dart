import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// A narrow presentation seam; production delegates to official video_player.
abstract interface class VideoPlayback
    implements ValueListenable<VideoPlayerValue> {
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Widget buildSurface();
  Future<void> dispose();
}

typedef VideoPlaybackFactory = VideoPlayback Function(File file);

class LocalVideoPlayback implements VideoPlayback {
  LocalVideoPlayback(File file)
    : _controller = VideoPlayerController.file(
        file,
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: false),
      );
  final VideoPlayerController _controller;
  @override
  VideoPlayerValue get value => _controller.value;
  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);
  @override
  Future<void> initialize() => _controller.initialize();
  @override
  Future<void> play() => _controller.play();
  @override
  Future<void> pause() => _controller.pause();
  @override
  Future<void> seekTo(Duration position) => _controller.seekTo(position);
  @override
  Widget buildSurface() => VideoPlayer(_controller);
  @override
  Future<void> dispose() => _controller.dispose();
}
