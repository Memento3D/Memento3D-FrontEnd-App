import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'video_recording.dart';

/// Shared capture footprint; library and next remain unavailable in Phase B.
class VideoCaptureControls extends StatelessWidget {
  const VideoCaptureControls({
    super.key,
    this.state = VideoRecordingState.idle,
    this.onRecord,
    this.hasVideo = false,
    this.onReview,
  });
  final VideoRecordingState state;
  final VoidCallback? onRecord;
  final bool hasVideo;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return SizedBox(
      height:
          86 + 90 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 2),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _DisabledControl(
                controlKey: Key(!hasVideo ? 'video-library' : 'video-preview'),
                onTap:
                    hasVideo &&
                        (state == VideoRecordingState.idle ||
                            state == VideoRecordingState.error)
                    ? onReview
                    : null,
                label: !hasVideo ? strings.captureLibrary : strings.preview,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2EEFF),
                            border: hasVideo
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.video_library_outlined,
                            color: Color(0xFF6B4FE8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      !hasVideo ? strings.captureLibrary : strings.preview,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _DisabledControl(
            controlKey: const Key('video-record'),
            onTap: onRecord,
            label: state == VideoRecordingState.recording
                ? strings.stopVideo
                : strings.recordVideo,
            child: Container(
              width: 78,
              height: 78,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6B4FE8).withValues(alpha: .18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF2EEFF),
                ),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: state == VideoRecordingState.recording
                          ? BoxShape.rectangle
                          : BoxShape.circle,
                      borderRadius: state == VideoRecordingState.recording
                          ? BorderRadius.circular(5)
                          : null,
                      color: const Color(0xFFD32F2F),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: _DisabledControl(
                controlKey: const Key('video-next'),
                label: strings.nextStep,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EEFF),
                    border: Border.all(color: const Color(0xFFD7CAFF)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    strings.nextStep,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B4FE8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledControl extends StatelessWidget {
  const _DisabledControl({
    required this.controlKey,
    required this.label,
    required this.child,
    this.onTap,
  });
  final Key controlKey;
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    key: controlKey,
    button: true,
    enabled: onTap != null,
    label: label,
    child: ExcludeSemantics(
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(opacity: onTap == null ? .55 : 1, child: child),
      ),
    ),
  );
}
