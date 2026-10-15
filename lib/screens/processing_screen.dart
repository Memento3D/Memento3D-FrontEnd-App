import 'dart:io';

import 'package:flutter/material.dart';

import '../features/scans/data/services/job_service.dart';
import '../features/scans/presentation/controllers/processing_progress_controller.dart';
import '../l10n/app_localizations.dart';
import 'capture_session.dart';
import 'processing_state.dart';
import 'job_failed_screen.dart';
import '../features/model_viewer/presentation/screens/model_viewer_screen.dart';
import '../features/home/presentation/screens/main_screen.dart';

const _purple = Color(0xFF5B3FD9);
const _lavender = Color(0xFFEEEBFF);
const _ink = Color(0xFF1C1831);
const _border = Color(0xFFECE7FB);

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
        builder: (_) => ModelViewerScreen(scanId: widget.scanId),
      ),
    );
  }

  void _handleFailed() {
    if (!mounted || _navigated) return;
    _navigated = true;
    widget.onFailed?.call();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => JobFailedScreen(
          jobId: _controller?.job?.id ?? '',
          scanId: widget.scanId,
          errorMessage: _controller?.errorMessage,
          jobService: widget.jobService,
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
    if (widget.scanId == null && provided != null) return provided;
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
      progress: controller.job?.progress,
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
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3EEFF), Color(0xFFFFF4F7), Color(0xFFF7F3FF)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              SizedBox(
                height: 58,
                child: Row(
                  children: [
                    _roundButton(
                      icon: Icons.keyboard_arrow_down_rounded,
                      tooltip: strings.back,
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _lavender,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: _purple,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Memento3D AI Engine',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _purple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: strings.back,
                      child: _roundButton(
                        icon: Icons.close_rounded,
                        tooltip: strings.moreOptions,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _previewCard(strings),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4DC),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_fix_high_rounded,
                        color: Color(0xFFC2410C),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          switch (snapshot.status) {
                            ProcessingStatus.waiting =>
                              strings.processingStagePending,
                            ProcessingStatus.running =>
                              strings.processingStageActive,
                            ProcessingStatus.completed =>
                              strings.processingStageCompleted,
                            ProcessingStatus.failed => strings.processingFailed,
                          },
                          style: const TextStyle(
                            color: Color(0xFFC2410C),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.processingProgressTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.processingProgressSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF6B6680),
                  fontSize: 13,
                  height: 1.45,
                ),
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Localizations.localeOf(context).languageCode ==
                                        'vi'
                                    ? 'TIẾN TRÌNH AI'
                                    : 'AI PROGRESS',
                                style: const TextStyle(
                                  color: Color(0xFF6B6680),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                stageLabel,
                                style: const TextStyle(
                                  color: _purple,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          progressPercent == null ? '--%' : '$progressPercent%',
                          style: const TextStyle(
                            color: _purple,
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
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
                      strings.processingHistoryTitle.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFF6B6680),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                        letterSpacing: 0.6,
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
                  color: const Color(0xFFF4F0FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE4DC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xFFC2410C),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.processingTipTitle,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            strings.processingTipBody,
                            style: const TextStyle(
                              color: Color(0xFF6B6680),
                              fontSize: 12,
                              height: 1.45,
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
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.notifications_active_outlined, size: 18),
                label: Text(strings.processingRunInBackground),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF4B4660),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: const Icon(Icons.dashboard_outlined, size: 17),
                label: const Text('Về danh sách phiên Scan (Dashboard)'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) => Material(
    color: _lavender,
    shape: const CircleBorder(),
    child: IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: _ink, size: 20),
      visualDensity: VisualDensity.compact,
    ),
  );

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
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: completed
                  ? const Color(0xFFD1FAE5)
                  : (active ? Colors.white : const Color(0xFFF3F1F8)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed
                  ? Icons.check_rounded
                  : (active ? Icons.sync_rounded : Icons.schedule_rounded),
              size: 15,
              color: completed
                  ? const Color(0xFF059669)
                  : (active ? _purple : const Color(0xFFA6A0B3)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              phaseLabelFor(strings, phase),
              style: TextStyle(
                color: active
                    ? _purple
                    : (completed ? _ink : const Color(0xFF8E89A0)),
                fontSize: 13,
                fontWeight: active || completed
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
          if (active)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusLabel,
                style: const TextStyle(
                  color: _purple,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Text(
              statusLabel,
              style: const TextStyle(color: Color(0xFF8E89A0), fontSize: 11),
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
