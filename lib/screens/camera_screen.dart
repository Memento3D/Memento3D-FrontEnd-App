import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../l10n/app_localizations.dart';
import 'camera_view.dart';
import 'video_recording.dart';
import 'capture_mode.dart';
import 'capture_review_screen.dart';
import 'video_preview_screen.dart';
import 'video_playback.dart';
import 'capture_session.dart';
import 'capture_wizard.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    this.developmentWrapper,
    this.cameraFactory,
    this.previewPlaybackFactory,
  });

  /// Hardware-free integration tests; controller ownership stays in this screen.
  final Future<CameraController> Function()? cameraFactory;
  final VideoPlaybackFactory? previewPlaybackFactory;

  /// Optional device-harness decoration; absent from production capture routes.
  final Widget Function(BuildContext, VideoRecordingDiagnostics, Widget)?
  developmentWrapper;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  final VideoRecordingCoordinator _video = VideoRecordingCoordinator();
  Future<void> _cameraRelease = Future.value();
  bool _foreground = true;
  bool _exiting = false;
  bool _allowPop = false;

  void _videoChanged() {
    if (!mounted) return;
    setState(() {});
    final error = _video.error;
    if (error != null && _video.state == VideoRecordingState.error) {
      final strings = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error == VideoRecordingError.finalize
                ? strings.videoFinalizeError
                : error == VideoRecordingError.unavailable
                ? strings.cameraError
                : strings.videoStartError,
          ),
        ),
      );
    }
  }

  Future<void> _releaseCamera() {
    ++_generation;
    final controller = _controller;
    _controller = null;
    _cameraRelease = _cameraRelease.then((_) async {
      await _video.quiesce();
      await controller?.dispose();
    });
    return _cameraRelease;
  }

  Future<void> _exit() async {
    if (_exiting) return;
    _exiting = true;
    setState(() {});
    await _releaseCamera();
    if (!mounted) return;
    setState(() => _allowPop = true);
    // PopScope must rebuild before the programmatic pop.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final exited = await Navigator.of(context).maybePop();
    if (!exited && mounted) {
      setState(() {
        _exiting = false;
        _allowPop = false;
      });
      if (_foreground) await _openCamera();
    }
  }

  void _record() {
    if (_exiting || !_foreground || _reviewOpen) return;
    if (_video.state == VideoRecordingState.recording) {
      unawaited(
        _video.stop().then((_) async {
          // A failed stop leaves plugin state uncertain: recycle before retry.
          if (_video.error == VideoRecordingError.finalize && mounted) {
            await _releaseCamera();
            if (mounted && _foreground && !_exiting) await _openCamera();
          }
        }),
      );
    } else {
      final controller = _controller;
      unawaited(
        _video.start(
          controller == null ? null : CameraVideoRecorder(controller),
        ),
      );
    }
  }

  CaptureMode _mode = CaptureMode.photo;
  final CaptureSession _session = CaptureSession();
  final CaptureWizardModel _wizard = CaptureWizardModel();
  StreamSubscription<AccelerometerEvent>? _gravitySubscription;
  StreamSubscription<UserAccelerometerEvent>? _accelerationSubscription;
  StreamSubscription<GyroscopeEvent>? _rotationSubscription;
  Future<void> _sensorStop = Future.value();
  Timer? _feedbackTimer;
  int _sensorEpoch = 0;
  bool _sensorActive = false;
  bool _capturing = false;
  bool _cameraFailed = false;
  bool _reviewOpen = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _video.addListener(_videoChanged);
    _openCamera();
    _startSensors();
  }

  void _startSensors() {
    if (_sensorActive) return;
    _sensorActive = true;
    final epoch = ++_sensorEpoch;
    unawaited(
      _sensorStop.then((_) {
        if (!mounted || !_sensorActive || epoch != _sensorEpoch) return;
        try {
          _gravitySubscription = accelerometerEventStream().listen(
            (sample) {
              if (!_sensorActive) return;
              setState(() => _wizard.addGravity(sample.x, sample.y, sample.z));
            },
            onError: (_) => _handleSensorError(_wizard.clearGravity),
            cancelOnError: true,
          );
        } catch (_) {
          _wizard.clearGravity();
        }
        try {
          _accelerationSubscription = userAccelerometerEventStream().listen(
            (sample) {
              if (!_sensorActive) return;
              setState(
                () => _wizard.addUserAcceleration(sample.x, sample.y, sample.z),
              );
            },
            onError: (_) => _handleSensorError(_wizard.clearAcceleration),
            cancelOnError: true,
          );
        } catch (_) {
          _wizard.clearAcceleration();
        }
        try {
          _rotationSubscription = gyroscopeEventStream().listen(
            (sample) {
              if (!_sensorActive) return;
              setState(() => _wizard.addRotation(sample.x, sample.y, sample.z));
            },
            onError: (_) => _handleSensorError(_wizard.clearRotation),
            cancelOnError: true,
          );
        } catch (_) {
          _wizard.clearRotation();
        }
      }),
    );
  }

  void _handleSensorError(VoidCallback clearReading) {
    if (mounted && _sensorActive) setState(clearReading);
  }

  void _stopSensors() {
    _sensorActive = false;
    ++_sensorEpoch;
    final subscriptions = [
      _gravitySubscription,
      _accelerationSubscription,
      _rotationSubscription,
    ];
    _gravitySubscription = null;
    _accelerationSubscription = null;
    _rotationSubscription = null;
    _sensorStop = Future.wait(
      subscriptions.whereType<StreamSubscription<dynamic>>().map(
        (subscription) => subscription.cancel(),
      ),
    );
    _wizard.resetSensors();
  }

  Future<void> _openCamera() async {
    final generation = ++_generation;
    await _cameraRelease;
    if (!mounted ||
        !_foreground ||
        _exiting ||
        _reviewOpen ||
        generation != _generation) {
      return;
    }
    final previous = _controller;
    setState(() {
      _controller = null;
      _cameraFailed = false;
    });
    await previous?.dispose();

    CameraController? controller;
    try {
      if (widget.cameraFactory != null) {
        controller = await widget.cameraFactory!();
      } else {
        final cameras = await availableCameras();
        if (cameras.isEmpty) throw StateError('No camera found');
        final camera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => cameras.first,
        );
        controller = CameraController(
          camera,
          ResolutionPreset.high,
          enableAudio: false,
        );
      }
      await controller.initialize();
      if (!mounted || generation != _generation) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      await controller?.dispose();
      if (mounted && generation == _generation) {
        setState(() => _cameraFailed = true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      unawaited(_releaseCamera());
      _stopSensors();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (!_exiting && !_reviewOpen) {
        _openCamera();
        _startSensors();
      }
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_exiting ||
        !_foreground ||
        _video.busy ||
        controller == null ||
        !controller.value.isInitialized ||
        _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final photo = await controller.takePicture();
      if (!mounted || controller != _controller) return;
      setState(() {
        _session.addPhoto(photo);
        _wizard.markCaptured(DateTime.now());
      });
      _feedbackTimer?.cancel();
      _feedbackTimer = Timer(CaptureWizardThresholds.captureFeedback, () {
        if (mounted) setState(() {});
      });
    } catch (_) {
      if (mounted) {
        final message = AppLocalizations.of(context)!.captureError;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _openReview() =>
      _showReview(CaptureReviewScreen(session: _session), video: false);

  Future<void> _openVideoReview() => _showReview(
    VideoPreviewScreen(
      session: _video.videoSession,
      playbackFactory: widget.previewPlaybackFactory,
    ),
    video: true,
  );

  Future<void> _showReview(Widget review, {required bool video}) async {
    if (_reviewOpen || _exiting || !_foreground || _capturing || _video.busy) {
      return;
    }
    if (video) {
      if (_mode != CaptureMode.video || !_video.videoSession.canReview) return;
    } else if (!_session.canReview) {
      return;
    }
    // Install navigation guard before any release or plugin awaits.
    setState(() => _reviewOpen = true);
    _stopSensors();
    try {
      await _releaseCamera();
      if (!mounted || !_foreground || _exiting) return;
      await Navigator.of(context)
          .push<void>(MaterialPageRoute(builder: (_) => review));
    } finally {
      _reviewOpen = false;
      if (mounted) {
        setState(() {});
        if (_foreground && !_exiting) {
          await _openCamera();
          if (mounted && _foreground && !_exiting) _startSensors();
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_generation;
    _feedbackTimer?.cancel();
    _stopSensors();
    unawaited(_releaseCamera());
    _video.removeListener(_videoChanged);
    _video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final capture = PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_exit());
      },
      child: CameraView(
        onBack: () => unawaited(_exit()),
        videoState: _video.state,
        videoElapsed: _video.elapsed,
        hasVideo: _video.videoSession.hasVideo,
        onVideoReview:
            _mode == CaptureMode.video &&
                _video.videoSession.canReview &&
                !_video.busy &&
                !_reviewOpen &&
                !_capturing &&
                !_exiting &&
                _foreground
            ? _openVideoReview
            : null,
        onVideoRecord:
            !_exiting &&
                !_reviewOpen &&
                _foreground &&
                !_capturing &&
                (_controller?.value.isInitialized ?? false) &&
                (_video.state == VideoRecordingState.recording || !_video.busy)
            ? _record
            : null,
        mode: _mode,
        onModeChanged: _capturing || _video.busy || _exiting || _reviewOpen
            ? null
            : (mode) => setState(() => _mode = mode),
        controller: _controller,
        capturedPhotos: _session.capturedPhotos,
        wizardState: _wizard.stateAt(DateTime.now()),
        capturing: _capturing,
        cameraFailed: _cameraFailed,
        onCapture: _capture,
        onRetry: _openCamera,
        onDone: _session.canReview ? _openReview : null,
      ),
    );
    return widget.developmentWrapper?.call(context, _video, capture) ?? capture;
  }
}
