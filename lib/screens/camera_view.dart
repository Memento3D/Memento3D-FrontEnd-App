import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'capture_wizard.dart';
import 'capture_mode.dart';
import 'capture_mode_switcher.dart';
import 'capture_bottom_navigation.dart';
import 'video_capture_controls.dart';
import 'video_recording.dart';

const _purple = Color(0xFF6B4FE8);
const _lavender = Color(0xFFF2EEFF);
const _ink = Color(0xFF29243D);
const _cardRadius = 24.0;

class CameraView extends StatelessWidget {
  const CameraView({
    super.key,
    required this.controller,
    required this.capturedPhotos,
    required this.wizardState,
    required this.capturing,
    required this.cameraFailed,
    required this.onCapture,
    required this.onRetry,
    required this.onDone,
    this.scanId,
    this.mode = CaptureMode.photo,
    this.onModeChanged,
    this.previewFrame,
    this.videoState = VideoRecordingState.idle,
    this.videoElapsed = Duration.zero,
    this.hasVideo = false,
    this.onVideoReview,
    this.onVideoLibrary,
    this.onPhotoLibrary,
    this.onVideoRecord,
    this.onBack,
  });

  final VideoRecordingState videoState;
  final Duration videoElapsed;
  final bool hasVideo;
  final VoidCallback? onVideoReview;
  final VoidCallback? onVideoLibrary;

  /// Adds existing photos from the device gallery to the capture session.
  final VoidCallback? onPhotoLibrary;
  final VoidCallback? onVideoRecord;
  final VoidCallback? onBack;
  final CaptureMode mode;
  final ValueChanged<CaptureMode>? onModeChanged;
  final CameraController? controller;
  final List<XFile> capturedPhotos;
  final CaptureWizardState wizardState;
  final bool capturing;
  final bool cameraFailed;
  final VoidCallback onCapture;
  final VoidCallback onRetry;
  final VoidCallback? onDone;
  final String? scanId;

  /// Optional presentation frame for development previews. Does not make a
  /// camera ready for capture or change controller ownership.
  final Widget? previewFrame;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final ready = controller?.value.isInitialized ?? false;
    final captureCount = capturedPhotos.length;
    final lastPhoto = capturedPhotos.isEmpty ? null : capturedPhotos.last;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFF),
      bottomNavigationBar: const CaptureBottomNavigation(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              SizedBox(
                height: 58,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack ?? () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back, color: _ink),
                      tooltip: strings.back,
                    ),
                    Expanded(
                      child: Text(
                        strings.captureTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (scanId != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _lavender,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          scanId!.length > 8
                              ? scanId!.substring(0, 8)
                              : scanId!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _purple,
                          ),
                        ),
                      ),
                    ],
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert, color: _ink),
                      tooltip: strings.moreOptions,
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: strings.profile,
                      child: const CircleAvatar(
                        radius: 18,
                        backgroundColor: _purple,
                        child: Icon(
                          Icons.person_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: AspectRatio(
                  aspectRatio: 0.80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_cardRadius),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColoredBox(
                          color: const Color(0xFFDDD5E5),
                          child:
                              previewFrame ??
                              (ready
                                  ? _LivePreview(controller: controller!)
                                  : Center(
                                      child: cameraFailed
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(strings.cameraError),
                                                TextButton(
                                                  onPressed: onRetry,
                                                  child: Text(strings.retry),
                                                ),
                                              ],
                                            )
                                          : const CircularProgressIndicator(),
                                    )),
                        ),
                        if (ready || previewFrame != null) ...[
                          // Capture guidance; no distance or balance measurements
                          // are claimed without a real measurement source.
                          Positioned(
                            top: 14,
                            left: 26,
                            right: 26,
                            child: _InstructionCard(
                              strings: strings,
                              state:
                                  mode == CaptureMode.video &&
                                      wizardState ==
                                          CaptureWizardState
                                              .capturedSuccessfully
                                  ? CaptureWizardState.ready
                                  : wizardState,
                            ),
                          ),
                          Positioned(
                            top: 94,
                            left: 30,
                            right: 30,
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (mode == CaptureMode.video &&
                                    videoState == VideoRecordingState.recording)
                                  _Pill(
                                    text:
                                        '\u25cf REC ${videoElapsed.inMinutes.toString().padLeft(2, '0')}:${(videoElapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                                    color: Colors.red,
                                  ),
                                if (mode == CaptureMode.photo) ...[
                                  _Pill(
                                    text: strings.capturedPhotos(captureCount),
                                    color: _purple,
                                  ),
                                ],
                                _Pill(
                                  text: strings.orbitLabel,
                                  color: const Color(0xFF258A5B),
                                  icon: Icons.rotate_right,
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: SizedBox(
                              width: 250,
                              height: 210,
                              child: Stack(
                                children: [const Center(child: _OrbitGuide())],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 14,
                            left: 14,
                            right: 14,
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (mode == CaptureMode.photo)
                                  _Pill(
                                    text: strings.naturalLight,
                                    color: _ink,
                                    icon: Icons.wb_sunny_outlined,
                                  ),
                                Tooltip(
                                  message: strings.grid,
                                  child: const CircleAvatar(
                                    radius: 17,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.grid_on,
                                      color: _purple,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CaptureModeSwitcher(mode: mode, onChanged: onModeChanged),
              const SizedBox(height: 12),
              if (mode == CaptureMode.photo)
                SizedBox(
                  height:
                      86 +
                      90 *
                          (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(
                            0,
                            2,
                          ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _Thumbnail(
                                  photo: lastPhoto,
                                  count: captureCount,
                                  label: strings.preview,
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  key: const Key('photo-library-button'),
                                  onPressed: onPhotoLibrary,
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                    color: _purple,
                                  ),
                                  tooltip: 'Chọn từ thư viện',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: strings.capturePhoto,
                        enabled: ready && !capturing,
                        child: GestureDetector(
                          onTap: ready && !capturing ? onCapture : null,
                          child: Container(
                            width: 78,
                            height: 78,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: _purple.withValues(alpha: 0.18),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: _purple,
                              ),
                              child: Center(
                                child: capturing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 5,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                key: const Key('photo-done-touch-target'),
                                behavior: HitTestBehavior.opaque,
                                onTap: onDone,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minWidth: 48,
                                    minHeight: 48,
                                  ),
                                  child: Center(
                                    widthFactor: 1,
                                    heightFactor: 1,
                                    child: Opacity(
                                      opacity: onDone == null ? 0.55 : 1,
                                      child: Container(
                                        key: const Key('photo-done-pill'),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _lavender,
                                          border: Border.all(
                                            color: const Color(0xFFD7CAFF),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check,
                                              color: _purple,
                                              size: 17,
                                            ),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                strings.done,
                                                style: const TextStyle(
                                                  color: _purple,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                VideoCaptureControls(
                  state: videoState,
                  hasVideo: hasVideo,
                  onReview: onVideoReview,
                  onLibrary: onVideoLibrary,
                  onRecord: onVideoRecord,
                ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({required this.controller});
  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = controller.value.previewSize!;
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.height,
            height: size.width,
            child: CameraPreview(controller),
          ),
        );
      },
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.strings, required this.state});
  final AppLocalizations strings;
  final CaptureWizardState state;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (state) {
      CaptureWizardState.ready => (
        strings.wizardReadyTitle,
        strings.wizardReadyBody,
      ),
      CaptureWizardState.tilted => (
        strings.wizardTiltedTitle,
        strings.wizardTiltedBody,
      ),
      CaptureWizardState.movingTooFast => (
        strings.wizardMovingTitle,
        strings.wizardMovingBody,
      ),
      CaptureWizardState.capturedSuccessfully => (
        strings.wizardCapturedTitle,
        strings.wizardCapturedBody,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _ink,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF696579), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.icon});
  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrbitGuide extends StatelessWidget {
  const _OrbitGuide();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(230, 190), painter: _OrbitPainter());
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final orbit = Paint()
      ..color = const Color(0xFF7A62FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawArc(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: 160,
        height: 125,
      ),
      0.2,
      4.8,
      false,
      orbit,
    );
    final corner = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final x in [22.0, size.width - 22]) {
      for (final y in [18.0, size.height - 18]) {
        final dx = x < size.width / 2 ? 1.0 : -1.0;
        final dy = y < size.height / 2 ? 1.0 : -1.0;
        final path = Path()
          ..moveTo(x + dx * 13, y)
          ..lineTo(x, y)
          ..lineTo(x, y + dy * 13);
        canvas.drawPath(path, corner);
      }
    }
    final dot = Paint()..color = const Color(0xFFFF8772);
    canvas.drawCircle(Offset(size.width / 2, size.height - 9), 5, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({
    required this.photo,
    required this.count,
    required this.label,
  });
  final XFile? photo;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 48,
              height: 48,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: _lavender,
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(14),
              ),
              child: photo == null
                  ? const Icon(Icons.photo_outlined, color: _purple)
                  : Image.file(
                      File(photo!.path),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: _purple,
                      ),
                    ),
            ),
            if (count > 0)
              Positioned(
                right: -3,
                bottom: -3,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: _purple,
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(color: _ink, fontSize: 11)),
      ],
    );
  }
}
