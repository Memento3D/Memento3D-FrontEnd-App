import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'capture_size_format.dart';
import 'video_capture_session.dart';
import 'video_duration_policy.dart';
import 'video_playback.dart';

/// Local single-video preview; player ownership never enters capture/session state.
class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({
    super.key,
    required this.session,
    this.playbackFactory,
  });
  final VideoCaptureSession session;
  final VideoPlaybackFactory? playbackFactory;
  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen>
    with WidgetsBindingObserver {
  LocalVideoSelection? _video;
  VideoPlayback? _player;
  VoidCallback? _playerListener;
  // Allow a fresh attempt after one broken disposal, but bound abandoned players.
  static const _maximumPendingBrokenCleanups = 2;
  int _pendingBrokenCleanups = 0;
  int? _currentBytes;
  bool _loading = true,
      _missing = false,
      _failed = false,
      _foreground = true,
      _commandBusy = false;
  int _generation = 0;
  Future<void> _commands = Future.value();
  Future<void> _release = Future.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant VideoPreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_video != widget.session.currentVideo) unawaited(_load());
  }

  void _changed() {
    if (!mounted) return;
    if ((_player?.value.hasError ?? false) && !_failed) {
      _failed = true;
      final player = _player;
      _commands = _commands.then((_) async {
        try {
          if (player == _player) await player?.pause();
        } catch (_) {
          /* Error already displayed. */
        }
      });
    }
    setState(() {});
  }

  Future<void> _releasePlayer({bool initializationFailed = false}) {
    final player = _player;
    _player = null;
    final listener = _playerListener;
    _playerListener = null;
    if (listener != null) player?.removeListener(listener);
    if (player == null) return _release;
    final commands = _commands;
    if (initializationFailed || !player.value.isInitialized) {
      // video_player disposal can await an unresolved native creation future.
      // Detach only failed/unfinished attempts from the healthy release queue.
      ++_pendingBrokenCleanups;
      unawaited(() async {
        try {
          await commands;
          await player.dispose();
        } catch (_) {
          /* Best-effort cleanup of an unavailable player. */
        } finally {
          --_pendingBrokenCleanups;
          if (mounted) setState(() {});
        }
      }());
      return _release;
    }
    // Drain in-flight play/pause before disposal so a late Play cannot escape.
    _release = _release.then((_) async {
      await commands;
      try {
        await player.dispose();
      } catch (_) {
        /* Already unavailable. */
      }
    });
    return _release;
  }

  Future<void> _load() async {
    if (_pendingBrokenCleanups >= _maximumPendingBrokenCleanups) return;
    final generation = ++_generation;
    _video = widget.session.currentVideo;
    final video = _video;
    setState(() {
      _loading = true;
      _missing = false;
      _failed = false;
      _currentBytes = null;
    });
    await _releasePlayer();
    if (!mounted || generation != _generation) return;
    if (video == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final bytes = await video.file.length();
      if (bytes <= 0) throw StateError('Empty video');
      final handle = await File(video.file.path).open();
      try {
        await handle.read(1);
      } finally {
        await handle.close();
      }
      if (!mounted || generation != _generation) return;
      _currentBytes = bytes;
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _missing = true;
        });
      }
      return;
    }
    try {
      final player = (widget.playbackFactory ?? LocalVideoPlayback.new)(
        File(video.file.path),
      );
      _player = player;
      void listener() {
        if (mounted && generation == _generation && player == _player) {
          _changed();
        }
      }

      _playerListener = listener;
      player.addListener(listener);
      await player.initialize();
      if (!mounted || generation != _generation || player != _player) return;
      await player.pause(); // Explicitly paused; no autoplay on open or resume.
      if (!mounted || generation != _generation || player != _player) return;
      setState(() {
        _loading = false;
        _failed = player.value.hasError || !player.value.isInitialized;
      });
      if (_failed) await _releasePlayer(initializationFailed: true);
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _failed = true;
        });
        await _releasePlayer(initializationFailed: true);
      }
    }
  }

  Future<void> _retry() async {
    // The callback may be invoked twice before the disabled button rebuilds.
    if (_loading) return;
    await _load();
  }

  Future<void> _toggle() async {
    final player = _player;
    if (player == null || _loading || _failed || !_foreground || _commandBusy) {
      return;
    }
    setState(() => _commandBusy = true);
    _commands = _commands.then((_) async {
      if (!mounted || player != _player || !_foreground) return;
      try {
        if (player.value.isPlaying) {
          await player.pause();
        } else {
          if (player.value.isCompleted ||
              player.value.position >= player.value.duration) {
            await player.seekTo(Duration.zero);
          }
          if (mounted && player == _player && _foreground) await player.play();
        }
      } catch (_) {
        if (mounted && player == _player) setState(() => _failed = true);
      }
    });
    await _commands;
    if (mounted) setState(() => _commandBusy = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _foreground = true);
      final player = _player;
      _commands = _commands.then((_) async {
        try {
          if (player != null && player == _player) await player.pause();
        } catch (_) {
          if (mounted) setState(() => _failed = true);
        }
      });
    } else {
      _foreground = false;
      final player = _player;
      _commands = _commands.then((_) async {
        try {
          if (player != null && player == _player) await player.pause();
        } catch (_) {
          if (mounted) setState(() => _failed = true);
        }
      });
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_generation;
    unawaited(_releasePlayer());
    super.dispose();
  }

  Widget _preview(AppLocalizations strings) {
    final player = _player;
    if (_loading) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(strings.videoLoading),
            ],
          ),
        ),
      );
    }
    if (_missing || _failed || player == null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Icon(
            Icons.video_library_outlined,
            size: 64,
            color: const Color(0xFF6B4FE8),
          ),
        ),
      );
    }
    final value = player.value;
    final ratio = value.aspectRatio.isFinite && value.aspectRatio > 0
        ? value.aspectRatio
        : 1.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: AspectRatio(
                  aspectRatio: ratio,
                  child: player.buildSurface(),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(strings.videoDuration(formatVideoDuration(value.duration))),
        Text(
          '${formatVideoDuration(value.position)} / ${formatVideoDuration(value.duration)}',
          key: const Key('video-position'),
        ),
        LinearProgressIndicator(
          value: value.duration.inMilliseconds > 0
              ? (value.position.inMilliseconds / value.duration.inMilliseconds)
                    .clamp(0.0, 1.0)
              : 0,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          key: const Key('video-play-pause'),
          onPressed: _foreground && !_commandBusy ? _toggle : null,
          icon: Icon(value.isPlaying ? Icons.pause : Icons.play_arrow),
          label: Text(value.isPlaying ? strings.videoPause : strings.videoPlay),
        ),
        if (!VideoDurationPolicy.isSatisfied(value.duration))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              strings.videoTooShort(VideoDurationPolicy.minimum.inSeconds),
              style: const TextStyle(color: Color(0xFF9A5760)),
            ),
          ),
        if (VideoDurationPolicy.isSatisfied(value.duration))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(strings.videoDurationSatisfied),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final video = _video;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCFAFF),
        title: Text(strings.videoPreviewTitle),
        leading: IconButton(
          tooltip: strings.back,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: video == null
              ? Text(strings.videoNotSelected)
              : Container(
                  key: const Key('selected-video-preview'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE6DFFF)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _preview(strings),
                      const SizedBox(height: 16),
                      Text(
                        video.file.name.replaceAll('\\', '/').split('/').last,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF29243D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(strings.videoFinalizedSize),
                      Text(
                        formatCaptureSize(strings, video.finalizedByteLength),
                        style: const TextStyle(
                          color: Color(0xFF6B4FE8),
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(strings.recordedVideo),
                      if (_missing)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            strings.videoUnavailable,
                            style: const TextStyle(color: Color(0xFF9A5760)),
                          ),
                        ),
                      if (_failed) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(strings.videoPlaybackError),
                        ),
                        TextButton(
                          onPressed:
                              _loading ||
                                  _pendingBrokenCleanups >=
                                      _maximumPendingBrokenCleanups
                              ? null
                              : _retry,
                          child: Text(strings.retry),
                        ),
                      ],
                      if (_currentBytes != null &&
                          _currentBytes != video.finalizedByteLength)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(strings.videoFileChanged),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
