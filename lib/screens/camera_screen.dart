import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../l10n/app_localizations.dart';
import 'camera_view.dart';
import 'capture_review_screen.dart';
import 'capture_session.dart';
import 'capture_wizard.dart';

class CameraScreen extends StatefulWidget {
  CameraScreen({super.key, required this.session, this.onUpload}) {
    if (session.scanId == null) {
      throw ArgumentError('CameraScreen requires a persisted scan session');
    }
  }

  /// The caller owns the scan identity and the session shared with review.
  final CaptureSession session;
  final Future<void> Function(BuildContext, CaptureSession)? onUpload;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CaptureSession get _session => widget.session;
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
    final previous = _controller;
    setState(() {
      _controller = null;
      _cameraFailed = false;
    });
    await previous?.dispose();

    CameraController? controller;
    try {
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
      ++_generation;
      final controller = _controller;
      _controller = null;
      controller?.dispose();
      _stopSensors();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _openCamera();
      _startSensors();
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) {
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

  Future<void> _openReview() async {
    if (!_session.canReview || _reviewOpen) return;
    _reviewOpen = true;
    ++_generation;
    final controller = _controller;
    setState(() => _controller = null);
    _stopSensors();
    await controller?.dispose();
    if (!mounted) return;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) =>
              CaptureReviewScreen(session: _session, onUpload: widget.onUpload),
        ),
      );
    } finally {
      _reviewOpen = false;
      if (mounted) {
        setState(() {});
        _openCamera();
        _startSensors();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ++_generation;
    _feedbackTimer?.cancel();
    _stopSensors();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CameraView(
      controller: _controller,
      capturedPhotos: _session.capturedPhotos,
      wizardState: _wizard.stateAt(DateTime.now()),
      capturing: _capturing,
      cameraFailed: _cameraFailed,
      onCapture: _capture,
      onRetry: _openCamera,
      onDone: _session.canReview ? _openReview : null,
    );
  }
}
