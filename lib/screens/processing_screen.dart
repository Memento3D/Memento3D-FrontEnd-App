import 'dart:io';

import 'package:flutter/material.dart';

import '../features/scans/data/services/job_service.dart';
import '../features/scans/presentation/controllers/processing_progress_controller.dart';
import '../l10n/app_localizations.dart';
import 'capture_session.dart';
import 'processing_state.dart';

const _purple = Color(0xFF6B4FE8);
const _lavender = Color(0xFFF2EEFF);
const _ink = Color(0xFF29243D);
const _border = Color(0xFFE6DFFF);

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({
    super.key,
    this.session,
    this.scanId,
    this.jobService,
    this.snapshot,
    this.onDone,
    this.onFailed,
  });

  /// Local capture session (optional; used for the preview card photo).
  final CaptureSession? session;

  /// When provided, the screen subscribes to the real backend job for
  /// this scan id (WebSocket + polling fallback).
  final String? scanId;

  /// Injectable for tests.
  final JobService? jobService;

  /// Optional pre-built snapshot (kept for POC/widget tests).
  final ProcessingSnapshot? snapshot;

  final VoidCallback? onDone;
  final VoidCallback? onFailed;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  ProcessingProgressController? _controller;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    final scanId = widget.scanId;
    if (scanId != null) {
      _controller = ProcessingProgressController(
        scanId: scanId,
        jobService: widget.jobService ?? JobService(),
        onDone: _handleDone,
        onFailed: _handleFailed,
      )..start();
    }
  }

  void _handleDone() {
    if (!mounted || _navigated) return;
    _navigated = true;
    widget.onDone?.call();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            ProcessingViewerPlaceholderScreen(scanId: widget.scanId),
      ),
    );
  }

  void _handleFailed() {
    if (!mounted || _navigated) return;
    _navigated = true;
    widget.onFailed?.call();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ProcessingFailedPlaceholderScreen(
          scanId: widget.scanId,
          message: _controller?.errorMessage,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  ProcessingSnapshot get _snapshot {
    final provided = widget.snapshot;
    if (provided != null) return provided;
    final controller = _controller;
    if (controller == null) return const ProcessingSnapshot.waiting();
    return ProcessingSnapshot(
      status: switch (controller.status) {
        ProcessingViewStatus.loading => ProcessingStatus.waiting,
        ProcessingViewStatus.running ||
        ProcessingViewStatus.reconnecting => ProcessingStatus.running,
        ProcessingViewStatus.completed => ProcessingStatus.completed,
        ProcessingViewStatus.failed => ProcessingStatus.failed,
      },
      stage: controller.stage,
      progress: controller.job?.effectiveProgress ?? controller.progress,
      etaSeconds: controller.etaSeconds,
      errorMessage: controller.errorMessage,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return AnimatedBuilder(
      animation: _controller ?? const AlwaysStoppedAnimation(0),
      builder: (context, _) => _buildBody(context, strings),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations strings) {
    final snapshot = _snapshot;
    final progress = snapshot.progress;
    final progressPercent = progress == null ? null : (progress * 100).round();
    final currentPhase = snapshot.currentPhase;
    final stageLabel = currentPhase == null
        ? strings.processingStagePending
        : strings.processingPhaseStep(
            currentPhase.index + 1,
            ProcessingPhase.values.length,
            phaseLabelFor(strings, currentPhase),
          );

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            SizedBox(
              height: 58,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: _ink),
                    tooltip: strings.back,
                  ),
                  const Spacer(),
                  Tooltip(
                    message: strings.back,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: _ink),
                      tooltip: strings.moreOptions,
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: _purple, size: 14),
                    const SizedBox(width: 6),
                    const Text(
                      'Memento3D AI Engine',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _previewCard(strings),
            const SizedBox(height: 18),
            Text(
              strings.processingProgressTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ink,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.processingProgressSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF777183), fontSize: 12),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stageLabel,
                          style: const TextStyle(color: _ink, fontSize: 11),
                        ),
                      ),
                      Text(
                        progressPercent == null ? '--%' : '$progressPercent%',
                        style: const TextStyle(
                          color: _purple,
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress ?? 0.0,
                      minHeight: 8,
                      backgroundColor: _lavender,
                      valueColor: const AlwaysStoppedAnimation(_purple),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatEta(strings, snapshot.etaSeconds),
                          style: const TextStyle(
                            color: Color(0xFF777183),
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (_controller?.isUsingPollingFallback == true)
                        Text(
                          strings.processingReconnecting,
                          style: const TextStyle(
                            color: Color(0xFFB45309),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.processingHistoryTitle,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final phase in ProcessingPhase.values)
                    _phaseRow(snapshot, phase, strings),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFBF7FF),
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: _purple, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.processingTipTitle,
                          style: const TextStyle(
                            color: _ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          strings.processingTipBody,
                          style: const TextStyle(
                            color: Color(0xFF777183),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(strings.processingBackgroundAck),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _purple,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text(strings.processingRunInBackground),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _previewCard(AppLocalizations strings) {
    final photo = widget.session?.latestPhoto;
    return Container(
      height: 282,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Container(
          width: 190,
          height: 215,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: _lavender,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _ink.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (photo == null)
                Center(
                  child: Text(
                    strings.processingMissingImage,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                Image.file(
                  File(photo.path),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        strings.processingMissingImage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _ink),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _phaseRow(
    ProcessingSnapshot snapshot,
    ProcessingPhase phase,
    AppLocalizations strings,
  ) {
    final stageStatus = snapshot.statusForPhase(phase);
    final active = stageStatus == ProcessingStageStatus.active;
    final completed = stageStatus == ProcessingStageStatus.completed;
    final statusLabel = switch (stageStatus) {
      ProcessingStageStatus.pending => strings.processingStagePending,
      ProcessingStageStatus.active => strings.processingStageActive,
      ProcessingStageStatus.completed => strings.processingStageCompleted,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: active ? _lavender : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_circle
                : (active ? Icons.sync_rounded : Icons.circle_outlined),
            size: 17,
            color: active || completed
                ? (completed ? const Color(0xFF10B981) : _purple)
                : const Color(0xFFA6A0B3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              phaseLabelFor(strings, phase),
              style: TextStyle(
                color: active ? _purple : _ink,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Text(
            statusLabel,
            style: const TextStyle(color: Color(0xFF777183), fontSize: 10),
          ),
        ],
      ),
    );
  }
}

String phaseLabelFor(AppLocalizations strings, ProcessingPhase phase) {
  switch (phase) {
    case ProcessingPhase.analyzing:
      return strings.processingPhaseAnalyzing;
    case ProcessingPhase.modeling:
      return strings.processingPhaseModeling;
    case ProcessingPhase.finishing:
      return strings.processingPhaseFinishing;
  }
}

String stageLabelFor(AppLocalizations strings, JobStage stage) {
  switch (stage) {
    case JobStage.queued:
      return strings.jobStageQueued;
    case JobStage.downloading:
      return strings.jobStageDownloading;
    case JobStage.preprocessing:
      return strings.jobStagePreprocessing;
    case JobStage.shapeGeneration:
      return strings.jobStageShapeGeneration;
    case JobStage.texturing:
      return strings.jobStageTexturing;
    case JobStage.validating:
      return strings.jobStageValidating;
    case JobStage.exporting:
      return strings.jobStageExporting;
    case JobStage.uploading:
      return strings.jobStageUploading;
    case JobStage.done:
      return strings.jobStageDone;
  }
}

String formatEta(AppLocalizations strings, int? etaSeconds) {
  if (etaSeconds == null) return strings.processingEtaUnknown;
  if (etaSeconds <= 60) return strings.processingEtaShort;
  final minutes = (etaSeconds / 60).round();
  if (minutes <= 1) return strings.processingEtaShort;
  return strings.processingEtaMinutes(minutes);
}

/// Placeholder for the 3D Viewer route ([#20]) until the real viewer
/// screen lands; receives the scan id.
class ProcessingViewerPlaceholderScreen extends StatelessWidget {
  const ProcessingViewerPlaceholderScreen({super.key, this.scanId});

  final String? scanId;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${strings.processingCompleted}\n${scanId ?? ''}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Error state navigation target ([#19]) until a dedicated failure
/// screen exists; shows the backend error when available.
class ProcessingFailedPlaceholderScreen extends StatelessWidget {
  const ProcessingFailedPlaceholderScreen({
    super.key,
    this.scanId,
    this.message,
  });

  final String? scanId;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFF),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '${strings.processingFailed}\n${message ?? ''}',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
