import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'capture_session.dart';
import 'capture_size_format.dart';
import 'processing_state.dart';

const _purple = Color(0xFF6B4FE8);
const _lavender = Color(0xFFF2EEFF);
const _ink = Color(0xFF29243D);
const _border = Color(0xFFE6DFFF);

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({
    super.key,
    required this.session,
    this.snapshot = const ProcessingSnapshot.waiting(),
  });

  final CaptureSession session;
  final ProcessingSnapshot snapshot;

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  late Future<CaptureSizeSummary> _sizeFuture;

  @override
  void initState() {
    super.initState();
    _sizeFuture = widget.session.measureSize();
  }

  @override
  void didUpdateWidget(covariant ProcessingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _sizeFuture = widget.session.measureSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
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
                  Text(
                    strings.processingTitle,
                    style: const TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.more_vert, color: _ink),
                    tooltip: strings.moreOptions,
                  ),
                  const SizedBox(width: 6),
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
            const SizedBox(height: 12),
            Row(
              children: [
                _statusPill(
                  strings.processingLocal,
                  Icons.phone_android_outlined,
                  _purple,
                ),
                const Spacer(),
                Flexible(
                  child: _statusPill(
                    widget.snapshot.status == ProcessingStatus.readyToUpload
                        ? strings.processingCloudUnavailable
                        : strings.processingCloudConnected,
                    Icons.cloud_off_outlined,
                    const Color(0xFF777183),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _previewCard(strings),
            const SizedBox(height: 18),
            _statusArea(strings),
            const SizedBox(height: 18),
            _localSummary(strings),
            const SizedBox(height: 18),
            _stageCard(strings),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

  Widget _previewCard(AppLocalizations strings) {
    final photo = widget.session.latestPhoto;
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
              Positioned(
                left: 10,
                bottom: 10,
                child: _statusPill(
                  strings.processingPhotoCount(widget.session.photoCount),
                  Icons.photo_library_outlined,
                  _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusArea(AppLocalizations strings) {
    final status = widget.snapshot.status;
    final title = switch (status) {
      ProcessingStatus.readyToUpload => strings.processingReadyTitle,
      ProcessingStatus.uploading => strings.processingUploading,
      ProcessingStatus.processing => strings.processingRunning,
      ProcessingStatus.completed => strings.processingCompleted,
      ProcessingStatus.failed => strings.processingFailed,
    };
    return Column(
      children: [
        if (widget.snapshot.hasMeasuredProgress)
          Text(
            '${widget.snapshot.progressPercent!.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: _purple,
              fontWeight: FontWeight.w700,
              fontSize: 42,
            ),
          )
        else
          const Icon(Icons.cloud_upload_outlined, color: _purple, size: 44),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          switch (status) {
            ProcessingStatus.readyToUpload => strings.processingReadyBody,
            ProcessingStatus.uploading ||
            ProcessingStatus.processing => strings.processingInProgressBody,
            ProcessingStatus.completed => strings.processingCompleteBody,
            ProcessingStatus.failed => strings.processingFailedBody,
          },
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF777183), fontSize: 12),
        ),
        const SizedBox(height: 10),
        Text(
          status == ProcessingStatus.readyToUpload
              ? strings.processingWaiting
              : strings.processingProgressPending,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _purple,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _localSummary(AppLocalizations strings) {
    final detail =
        widget.session.detailLevel == ReconstructionDetailLevel.standard
        ? strings.detailStandard
        : strings.detailHigh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.tune, color: _purple, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  strings.processingSelectedDetail,
                  style: const TextStyle(color: _ink, fontSize: 12),
                ),
              ),
              Text(
                detail,
                style: const TextStyle(
                  color: _purple,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: _border),
          Row(
            children: [
              const Icon(Icons.folder_outlined, color: _purple, size: 17),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  strings.processingFileSize,
                  style: const TextStyle(color: _ink, fontSize: 12),
                ),
              ),
              FutureBuilder<CaptureSizeSummary>(
                future: _sizeFuture,
                builder: (context, snapshot) => Text(
                  snapshot.data == null
                      ? strings.sizeCalculating
                      : formatCaptureSize(strings, snapshot.data!.bytes),
                  style: const TextStyle(
                    color: _purple,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          FutureBuilder<CaptureSizeSummary>(
            future: _sizeFuture,
            builder: (context, snapshot) =>
                (snapshot.data?.unavailableFiles ?? 0) == 0
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      strings.sizeIncomplete,
                      style: const TextStyle(
                        color: Color(0xFF9A5760),
                        fontSize: 11,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stageCard(AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_outlined, color: _purple, size: 18),
              const SizedBox(width: 7),
              Text(
                strings.processingStageTitle,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.snapshot.status == ProcessingStatus.readyToUpload
                ? strings.processingNotStarted
                : strings.processingInProgressBody,
            style: const TextStyle(color: Color(0xFF777183), fontSize: 11),
          ),
          const Divider(height: 20, color: _border),
          for (final stage in ProcessingStage.values) _stageRow(stage, strings),
        ],
      ),
    );
  }

  Widget _stageRow(ProcessingStage stage, AppLocalizations strings) {
    final stageStatus = widget.snapshot.statusFor(stage);
    final label = switch (stage) {
      ProcessingStage.dataUpload => strings.processingStageUpload,
      ProcessingStage.imagePreparation => strings.processingStagePrepare,
      ProcessingStage.structureReconstruction =>
        strings.processingStageStructure,
      ProcessingStage.detailGeneration => strings.processingStageDetail,
      ProcessingStage.texturing => strings.processingStageTexture,
      ProcessingStage.completion => strings.processingStageComplete,
    };
    final statusLabel = switch (stageStatus) {
      ProcessingStageStatus.pending => strings.processingStagePending,
      ProcessingStageStatus.active => strings.processingStageActive,
      ProcessingStageStatus.completed => strings.processingStageCompleted,
    };
    final active = stageStatus == ProcessingStageStatus.active;
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
            stageStatus == ProcessingStageStatus.completed
                ? Icons.check_circle
                : Icons.circle_outlined,
            size: 17,
            color: active ? _purple : const Color(0xFFA6A0B3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
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
