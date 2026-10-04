import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../screens/capture_session.dart';
import '../../../../screens/capture_size_format.dart';
import '../../domain/models/upload_progress_snapshot.dart';
import '../controllers/upload_progress_controller.dart';

const _background = Color(0xFFFDF8FF);
const _primary = Color(0xFF5B3CDD);
const _container = Color(0xFF7459F7);
const _fixed = Color(0xFFE5DEFF);
const _surface = Color(0xFFF1EBFF);
const _surfaceLow = Color(0xFFF7F1FF);
const _ink = Color(0xFF1C1831);
const _secondary = Color(0xFF484555);
const _success = Color(0xFF006A3B);
const _error = Color(0xFFBA1A1A);
const _warning = Color(0xFF8A4B00);

/// A presentation surface for one caller-owned upload controller. It never
/// creates an upload or routes to processing/reconstruction. CaptureSession is
/// local input only; the caller supplies confirmed upload state independently.
class UploadProgressScreen extends StatefulWidget {
  const UploadProgressScreen({
    super.key,
    required this.controller,
    required this.session,
    required this.onUploadCompleted,
    this.objectName,
    this.onBack,
  });

  final UploadProgressController controller;
  final CaptureSession session;
  final String? objectName;
  final VoidCallback onUploadCompleted;
  final VoidCallback? onBack;

  @override
  State<UploadProgressScreen> createState() => _UploadProgressScreenState();
}

class _UploadProgressScreenState extends State<UploadProgressScreen> {
  late Future<CaptureSizeSummary> _localSize;

  @override
  void initState() {
    super.initState();
    _localSize = widget.session.measureSize();
    widget.controller.addListener(_checkCompletion);
    _checkCompletion();
  }

  @override
  void didUpdateWidget(covariant UploadProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _localSize = widget.session.measureSize();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_checkCompletion);
      widget.controller.addListener(_checkCompletion);
      _checkCompletion();
    }
  }

  void _checkCompletion() {
    final controller = widget.controller;
    if (controller.state.status != UploadProgressStatus.completed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.controller == controller &&
          controller.takeCompletion()) {
        widget.onUploadCompleted();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkCompletion);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.apply(
          fontFamily: 'PlusJakartaSans',
          bodyColor: _ink,
          displayColor: _ink,
        ),
        colorScheme: theme.colorScheme.copyWith(
          primary: _primary,
          surface: Colors.white,
          onSurface: _ink,
        ),
      ),
      child: Scaffold(
        backgroundColor: _background,
        body: SafeArea(
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final state = widget.controller.state;
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      _header(strings),
                      const SizedBox(height: 10),
                      _summary(strings, state),
                      const SizedBox(height: 14),
                      if (state.status ==
                          UploadProgressStatus.waitingForNetwork)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _connectionWarning(strings),
                        ),
                      _uploadCard(strings, state),
                      const SizedBox(height: 20),
                      _photos(strings, state),
                      const SizedBox(height: 18),
                      _safety(strings, state),
                      const SizedBox(height: 14),
                      _detail(strings),
                      const SizedBox(height: 14),
                      _nextSteps(strings, state),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(AppLocalizations strings) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        IconButton(
          onPressed: widget.onBack ?? () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, color: _ink),
          tooltip: strings.back,
        ),
        Expanded(
          child: Text(
            strings.uploadTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: null,
          icon: const Icon(Icons.more_horiz, color: _secondary),
          tooltip: strings.moreOptions,
        ),
        Tooltip(
          message: strings.profile,
          child: const CircleAvatar(
            radius: 18,
            backgroundColor: _fixed,
            child: Icon(Icons.person_outline, color: _primary, size: 21),
          ),
        ),
      ],
    ),
  );

  Widget _summary(
    AppLocalizations strings,
    UploadProgressSnapshot state,
  ) => _Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _LocalPhoto(
                  photo: widget.session.latestPhoto,
                  fallbackLabel: strings.imageUnavailable,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.objectName ?? strings.captureSessionTitle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<CaptureSizeSummary>(
                    future: _localSize,
                    builder: (context, snapshot) => Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Text(
                          strings.uploadPhotoCount(widget.session.photoCount),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _secondary,
                          ),
                        ),
                        Text(
                          state.totalBytes != null
                              ? formatCaptureSize(strings, state.totalBytes!)
                              : snapshot.data == null
                              ? strings.sizeCalculating
                              : formatCaptureSize(
                                  strings,
                                  snapshot.data!.bytes,
                                ),
                          style: const TextStyle(
                            fontSize: 11,
                            color: _secondary,
                          ),
                        ),
                        if ((snapshot.data?.unavailableFiles ?? 0) > 0)
                          Text(
                            strings.sizeIncomplete,
                            style: const TextStyle(
                              fontSize: 11,
                              color: _secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.uploadSummaryProgress(_percentage(state)),
                    style: const TextStyle(
                      fontSize: 11,
                      color: _primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Tag(
              label: _status(strings, state.status),
              color: _statusColor(state.status),
            ),
            _Tag(
              label: strings.uploadLocalPhotos,
              icon: Icons.photo_library_outlined,
            ),
            if (state.supportsPersistentResume)
              _Tag(
                label: strings.uploadSavedTitle,
                icon: Icons.shield_outlined,
              ),
          ],
        ),
      ],
    ),
  );

  Widget _connectionWarning(AppLocalizations strings) => _Card(
    color: const Color(0xFFFFEEDB),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.wifi_off_outlined, color: _warning, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.uploadNetworkBanner,
                style: const TextStyle(
                  color: _warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                strings.uploadNetworkBody,
                style: const TextStyle(
                  color: _warning,
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _uploadCard(AppLocalizations strings, UploadProgressSnapshot state) {
    final color = _statusColor(state.status);
    final completed = state.status == UploadProgressStatus.completed;
    final title = switch (state.status) {
      UploadProgressStatus.preparing => strings.uploadPreparing,
      UploadProgressStatus.reconciling => strings.uploadReconcilingTitle,
      UploadProgressStatus.completed => strings.uploadCompleted,
      UploadProgressStatus.recoverableFailure => strings.uploadRetryNeeded,
      _ => strings.uploadMainTitle,
    };
    final speed = state.visibleBytesPerSecond;
    final eta = state.visibleRemaining;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                completed
                    ? Icons.check_circle_outline
                    : Icons.cloud_upload_outlined,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            strings.uploadPercent(_percentage(state)),
            key: const Key('upload-percentage'),
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w800,
              color: color,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _ConfirmedBar(
            value: state.confirmedProgress,
            animate: state.status == UploadProgressStatus.uploading,
            color: color,
            semanticsLabel: strings.uploadProgressLabel,
            semanticsValue: strings.uploadPercent(_percentage(state)),
          ),
          const SizedBox(height: 10),
          Text(
            strings.uploadConfirmedParts(
              state.confirmedUnits,
              state.totalUnits,
            ),
            key: const Key('upload-confirmed-count'),
            style: const TextStyle(fontSize: 12, color: _secondary),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked =
                  constraints.maxWidth < 260 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.4;
              final metrics = [
                _Metric(
                  value: speed == null
                      ? strings.uploadUnknownMetric
                      : strings.uploadSpeedValue(
                          (speed / 1000000).toStringAsFixed(1),
                        ),
                  label: strings.uploadSpeed,
                ),
                _Metric(
                  value: eta != null
                      ? strings.uploadEtaValue(
                          eta.inSeconds ~/ 60,
                          eta.inSeconds % 60,
                        )
                      : state.status == UploadProgressStatus.waitingForNetwork
                      ? strings.uploadEtaWaiting
                      : strings.uploadUnknownMetric,
                  label: strings.uploadRemaining,
                ),
                _Metric(
                  value: strings.uploadUnitCount(
                    state.confirmedUnits,
                    state.totalUnits,
                  ),
                  label: strings.uploadConfirmed,
                ),
              ];
              if (stacked) {
                return Wrap(spacing: 16, runSpacing: 12, children: metrics);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final metric in metrics) Expanded(child: metric),
                ],
              );
            },
          ),
          if (state.status == UploadProgressStatus.reconciling ||
              state.status == UploadProgressStatus.completed ||
              state.canRetry) ...[
            const SizedBox(height: 14),
            Text(
              switch (state.status) {
                UploadProgressStatus.reconciling =>
                  strings.uploadReconcilingBody,
                UploadProgressStatus.completed => strings.uploadCompletionBody,
                _ =>
                  state.failure == UploadFailure.sourceUnavailable
                      ? strings.uploadSourceFailureBody
                      : strings.uploadFailureBody,
              },
              style: const TextStyle(
                fontSize: 12,
                color: _secondary,
                height: 1.5,
              ),
            ),
          ],
          if (state.canRetry) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('upload-retry'),
              onPressed: widget.controller.canRetry
                  ? widget.controller.retry
                  : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size(100, 48),
                backgroundColor: _primary,
              ),
              icon: const Icon(Icons.refresh),
              label: Text(strings.retry),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photos(AppLocalizations strings, UploadProgressSnapshot state) {
    final photos = widget.session.capturedPhotos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.uploadPhotosTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                constraints.maxWidth < 280 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.4
                ? 2
                : 4;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(4, (index) {
                final status = state.status == UploadProgressStatus.completed
                    ? index < photos.length
                          ? UploadPhotoStatus.completed
                          : UploadPhotoStatus.pending
                    : index < state.photoStatuses.length
                    ? state.photoStatuses[index]
                    : UploadPhotoStatus.pending;
                final restoring =
                    state.status == UploadProgressStatus.reconciling;
                final paused =
                    status == UploadPhotoStatus.current &&
                    state.status != UploadProgressStatus.uploading;
                final photoLabel = strings.photoNumber(index + 1);
                final statusLabel = switch (status) {
                  UploadPhotoStatus.completed => strings.uploadPhotoCompleted,
                  UploadPhotoStatus.current =>
                    restoring
                        ? strings.uploadReconciling
                        : paused
                        ? strings.uploadPhotoPaused
                        : strings.uploadPhotoCurrent,
                  UploadPhotoStatus.pending => strings.uploadPhotoPending,
                };
                return SizedBox(
                  width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                  child: Semantics(
                    label: strings.uploadPhotoDescription(
                      photoLabel,
                      statusLabel,
                    ),
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              key: ValueKey('upload-photo-$index'),
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: status == UploadPhotoStatus.current
                                    ? _fixed
                                    : _surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: status == UploadPhotoStatus.current
                                      ? _primary
                                      : _surface,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    _LocalPhoto(
                                      photo: index < photos.length
                                          ? photos[index]
                                          : null,
                                      fallbackLabel: strings.imageUnavailable,
                                    ),
                                    Positioned(
                                      right: 3,
                                      top: 3,
                                      child: DecoratedBox(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: Icon(
                                            switch (status) {
                                              UploadPhotoStatus.completed =>
                                                Icons.check,
                                              UploadPhotoStatus.current =>
                                                restoring
                                                    ? Icons.sync
                                                    : paused
                                                    ? Icons.pause
                                                    : Icons.arrow_upward,
                                              UploadPhotoStatus.pending =>
                                                Icons.more_horiz,
                                            },
                                            size: 15,
                                            color:
                                                status ==
                                                    UploadPhotoStatus.completed
                                                ? _success
                                                : _primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            statusLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: status == UploadPhotoStatus.completed
                                  ? _success
                                  : _secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _safety(AppLocalizations strings, UploadProgressSnapshot state) =>
      _Card(
        color: _surfaceLow,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shield_outlined, color: _primary, size: 23),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.supportsPersistentResume
                        ? strings.uploadSavedTitle
                        : strings.uploadSessionOnlyTitle,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    state.supportsPersistentResume
                        ? strings.uploadSavedBody
                        : strings.uploadSessionOnlyBody,
                    style: const TextStyle(
                      fontSize: 11,
                      color: _secondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _detail(AppLocalizations strings) => _Card(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.tune, color: _primary, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            strings.detailTitle,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            widget.session.detailLevel == ReconstructionDetailLevel.standard
                ? strings.detailStandard
                : strings.detailHigh,
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 12,
              color: _primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _nextSteps(AppLocalizations strings, UploadProgressSnapshot state) =>
      _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.uploadNextSteps,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            _Step(
              icon: state.status == UploadProgressStatus.completed
                  ? Icons.check
                  : Icons.cloud_upload_outlined,
              title: strings.uploadCloudStep,
              body: strings.uploadStepProgress(
                _status(strings, state.status),
                state.confirmedUnits,
                state.totalUnits,
              ),
              trailing: strings.uploadPercent(_percentage(state)),
              color: _primary,
            ),
            const Divider(height: 24, color: _fixed),
            _Step(
              icon: Icons.fact_check_outlined,
              title: strings.uploadQualityStep,
              body: strings.uploadQualityNextBody,
              trailing: strings.uploadNext,
              color: _secondary,
            ),
          ],
        ),
      );
}

String _percentage(UploadProgressSnapshot state) {
  if (state.status == UploadProgressStatus.completed) return '100';
  // Integer division floors without floating-point rounding at boundaries.
  final percent = state.totalUnits == 0
      ? 0
      : state.confirmedUnits * 100 ~/ state.totalUnits;
  return percent.clamp(0, 99).toString();
}

String _status(AppLocalizations strings, UploadProgressStatus status) =>
    switch (status) {
      UploadProgressStatus.preparing => strings.uploadPreparing,
      UploadProgressStatus.uploading => strings.uploadUploading,
      UploadProgressStatus.waitingForNetwork => strings.uploadWaiting,
      UploadProgressStatus.reconciling => strings.uploadReconciling,
      UploadProgressStatus.completed => strings.uploadCompleted,
      UploadProgressStatus.recoverableFailure => strings.uploadRetryNeeded,
    };

Color _statusColor(UploadProgressStatus status) => switch (status) {
  UploadProgressStatus.waitingForNetwork => _warning,
  UploadProgressStatus.completed => _success,
  UploadProgressStatus.recoverableFailure => _error,
  _ => _primary,
};

class _Card extends StatelessWidget {
  const _Card({required this.child, this.color = Colors.white});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _surface),
    ),
    child: child,
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.color = _primary, this.icon});
  final String label;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          if (icon != null)
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Icon(icon, size: 13, color: color),
              ),
            ),
          TextSpan(text: label),
        ],
      ),
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 10, color: _secondary)),
    ],
  );
}

class _Step extends StatelessWidget {
  const _Step({
    required this.icon,
    required this.title,
    required this.body,
    required this.trailing,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String body;
  final String trailing;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CircleAvatar(
        radius: 17,
        backgroundColor: _surfaceLow,
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 5),
            Text(
              body,
              style: const TextStyle(
                fontSize: 10,
                color: _secondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              trailing,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _LocalPhoto extends StatelessWidget {
  const _LocalPhoto({required this.photo, required this.fallbackLabel});
  final XFile? photo;
  final String fallbackLabel;
  Widget _fallback() => ColoredBox(
    color: _surface,
    child: Center(
      child: Tooltip(
        message: fallbackLabel,
        child: Icon(
          Icons.image_outlined,
          color: _container.withValues(alpha: 0.65),
          size: 26,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => photo == null || photo!.path.isEmpty
      ? _fallback()
      : Image.file(
          File(photo!.path),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        );
}

/// Only the bar interpolates. The number and accessibility value always expose
/// the exact confirmed snapshot. Paused/error/reconciliation snap to that value.
class _ConfirmedBar extends StatelessWidget {
  const _ConfirmedBar({
    required this.value,
    required this.animate,
    required this.color,
    required this.semanticsLabel,
    required this.semanticsValue,
  });
  final double value;
  final bool animate;
  final Color color;
  final String semanticsLabel;
  final String semanticsValue;
  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticsLabel,
    value: semanticsValue,
    child: ExcludeSemantics(
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: animate && !MediaQuery.disableAnimationsOf(context)
            ? const Duration(milliseconds: 300)
            : Duration.zero,
        builder: (context, visualValue, _) => LinearProgressIndicator(
          key: const Key('upload-progress-bar'),
          value: visualValue.clamp(0, value),
          minHeight: 9,
          borderRadius: BorderRadius.circular(20),
          backgroundColor: _fixed,
          color: color,
        ),
      ),
    ),
  );
}
