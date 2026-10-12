import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../controllers/processing_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../screens/capture_session.dart';
import '../../../../screens/capture_size_format.dart';
import '../models/processing_state.dart';
import '../../domain/reconstruction_repository.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.session,
    this.snapshot = const ProcessingSnapshot.waiting(),
    this.controller,
    this.onContinue,
  });
  final CaptureSession session;
  final ProcessingSnapshot snapshot;

  /// Caller owns and disposes the controller; this screen only listens to it.
  final ProcessingController? controller;
  final VoidCallback? onContinue;
  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  late Future<CaptureSizeSummary> _sizeFuture;
  ProcessingSnapshot get snapshot =>
      widget.controller?.snapshot ?? widget.snapshot;
  @override
  void initState() {
    super.initState();
    _sizeFuture = widget.session.measureSize();
    widget.controller?.addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void didUpdateWidget(covariant ProcessingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _sizeFuture = widget.session.measureSize();
    }
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_changed);
      widget.controller?.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: strings.back,
                ),
                Expanded(
                  child: Text(
                    strings.processingTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(strings.processingLocal, Icons.phone_android_outlined),
                _pill(
                  snapshot.provenance == ProgressProvenance.simulated
                      ? strings.processingSimulated
                      : strings.processingCloudUnavailable,
                  snapshot.provenance == ProgressProvenance.simulated
                      ? Icons.science_outlined
                      : Icons.cloud_off_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _previewCard(strings),
            const SizedBox(height: 20),
            _statusArea(strings),
            const SizedBox(height: 20),
            _localSummary(strings),
            const SizedBox(height: 20),
            _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.processingStageTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final stage in ProcessingStage.values)
                    _stageRow(stage, strings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );

  Widget _pill(String text, IconData icon) => _card(
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(text, style: Theme.of(context).textTheme.labelMedium),
        ),
      ],
    ),
  );

  Widget _previewCard(AppLocalizations strings) => _card(
    Column(
      children: [
        SizedBox(
          height: 160,
          child: widget.session.latestPhoto == null
              ? Center(
                  child: Text(
                    strings.processingMissingImage,
                    textAlign: TextAlign.center,
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(widget.session.latestPhoto!.path),
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) => Center(
                      child: Text(
                        strings.processingMissingImage,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        Text(strings.processingPhotoCount(widget.session.photoCount)),
      ],
    ),
  );

  Widget _statusArea(AppLocalizations strings) {
    final status = snapshot.status;
    final simulated = snapshot.provenance == ProgressProvenance.simulated;
    final title = switch (status) {
      ProcessingStatus.queued => 'Queued',
      ProcessingStatus.cancelled => 'Cancelled',
      ProcessingStatus.readyToUpload => strings.processingReadyTitle,
      ProcessingStatus.uploading => strings.processingUploading,
      ProcessingStatus.processing => strings.processingRunning,
      ProcessingStatus.completed =>
        simulated
            ? strings.processingDemoCompleted
            : strings.processingCompleted,
      ProcessingStatus.failed => strings.processingFailed,
    };
    final body = switch (status) {
      ProcessingStatus.queued => 'Waiting for reconstruction.',
      ProcessingStatus.cancelled => 'Reconstruction was cancelled.',
      ProcessingStatus.readyToUpload => strings.processingReadyBody,
      ProcessingStatus.uploading ||
      ProcessingStatus.processing => strings.processingTakesTime,
      ProcessingStatus.completed =>
        simulated
            ? strings.processingDemoCompleteBody
            : strings.processingCompleteBody,
      ProcessingStatus.failed =>
        snapshot.errorMessage ??
            switch (snapshot.failure) {
              ProcessingFailure.simulated => strings.processingDemoFailure,
              ProcessingFailure.sourceUnavailable =>
                strings.processingSourceFailure,
              null => strings.processingFailedBody,
            },
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot.observationError != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(switch (snapshot.observationError!) {
              ReconstructionObservationError.authentication =>
                strings.processingObservationAuth,
              ReconstructionObservationError.unavailable =>
                strings.processingObservationUnavailable,
              ReconstructionObservationError.contract =>
                strings.processingObservationContract,
              ReconstructionObservationError.transient =>
                strings.processingObservationTransient,
              ReconstructionObservationError.exhausted =>
                strings.processingObservationExhausted,
              ReconstructionObservationError.request =>
                strings.processingSourceFailure,
            }, textAlign: TextAlign.center),
          ),
          if (snapshot.canRetryObservation && widget.controller != null)
            FilledButton(
              onPressed: widget.controller!.isRetrying
                  ? null
                  : widget.controller!.retry,
              child: Text(strings.retry),
            ),
          const SizedBox(height: 12),
        ],
        if (snapshot.isRunning && snapshot.observationError == null) ...[
          Center(child: CircularProgressIndicator(semanticsLabel: title)),
          const SizedBox(height: 16),
        ] else
          Icon(
            status == ProcessingStatus.completed
                ? Icons.check_circle
                : status == ProcessingStatus.failed
                ? Icons.error_outline
                : Icons.cloud_upload_outlined,
            color: status == ProcessingStatus.failed
                ? AppColors.error
                : AppColors.primary,
            size: 44,
          ),
        if (snapshot.hasKnownProgress) ...[
          Text(
            '${snapshot.progressPercent!.toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: snapshot.progressPercent! / 100,
            semanticsLabel: strings.processingStageTitle,
            semanticsValue: '${snapshot.progressPercent!.toStringAsFixed(0)}%',
          ),
          const SizedBox(height: 12),
        ],
        Semantics(
          liveRegion: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        Text(body, textAlign: TextAlign.center),
        if (status == ProcessingStatus.readyToUpload) ...[
          const SizedBox(height: 8),
          Text(strings.processingWaiting, textAlign: TextAlign.center),
        ],
        if (status == ProcessingStatus.completed) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.onContinue ?? () => Navigator.maybePop(context),
            child: Text(strings.processingReturn),
          ),
        ],
        if (status == ProcessingStatus.failed &&
            snapshot.canRetry &&
            widget.controller != null) ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: widget.controller!.isRetrying
                ? null
                : widget.controller!.retry,
            child: Text(strings.retry),
          ),
        ],
      ],
    );
  }

  Widget _localSummary(AppLocalizations strings) => _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          strings.processingSelectedDetail,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Text(
          widget.session.detailLevel == ReconstructionDetailLevel.standard
              ? strings.detailStandard
              : strings.detailHigh,
        ),
        const Divider(height: 24),
        Text(
          strings.processingFileSize,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        FutureBuilder<CaptureSizeSummary>(
          future: _sizeFuture,
          builder: (context, size) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                size.data == null
                    ? strings.sizeCalculating
                    : formatCaptureSize(strings, size.data!.bytes),
              ),
              if ((size.data?.unavailableFiles ?? 0) > 0)
                Text(strings.sizeIncomplete),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _stageRow(ProcessingStage stage, AppLocalizations strings) {
    final stageStatus = snapshot.status == ProcessingStatus.completed
        ? ProcessingStageStatus.completed
        : snapshot.statusFor(stage);
    final active = stageStatus == ProcessingStageStatus.active;
    final failedHere = active && snapshot.status == ProcessingStatus.failed;
    final label = switch (stage) {
      ProcessingStage.dataUpload => strings.processingStageUpload,
      ProcessingStage.imagePreparation => strings.processingStagePrepare,
      ProcessingStage.structureReconstruction =>
        strings.processingStageStructure,
      ProcessingStage.detailGeneration => strings.processingStageDetail,
      ProcessingStage.texturing => strings.processingStageTexture,
      ProcessingStage.completion => strings.processingStageComplete,
    };
    final statusLabel = failedHere
        ? strings.processingStoppedHere
        : switch (stageStatus) {
            ProcessingStageStatus.pending => strings.processingStagePending,
            ProcessingStageStatus.active => strings.processingStageActive,
            ProcessingStageStatus.completed => strings.processingStageCompleted,
          };
    return Semantics(
      label: '$label: $statusLabel',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('stage-${stage.name}-${stageStatus.name}'),
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.badgePurpleBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              failedHere
                  ? Icons.error_outline
                  : stageStatus == ProcessingStageStatus.completed
                  ? Icons.check_circle
                  : active
                  ? Icons.pending_outlined
                  : Icons.circle_outlined,
              color: failedHere
                  ? AppColors.error
                  : active
                  ? AppColors.primary
                  : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
