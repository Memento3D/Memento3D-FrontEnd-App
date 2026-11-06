import '../features/customization/presentation/create_model_screen.dart';

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../features/reconstruction/data/api/reconstruction_job_start_api.dart';
import '../features/reconstruction/data/repositories/reconstruction_job_start_repository_impl.dart';
import '../features/reconstruction/domain/models/reconstruction_failure.dart';
import '../features/reconstruction/domain/repositories/reconstruction_job_start_repository.dart';
import '../features/scans/data/models/scan_model.dart';
import '../features/scans/data/models/scan_item.dart';
import '../features/scans/presentation/screens/scan_wizard_screen.dart';
import '../features/uploads/data/local/local_photo_file.dart';
import '../features/uploads/domain/models/photo_upload_manifest.dart';
import '../features/uploads/domain/models/upload_progress_snapshot.dart';
import '../features/uploads/domain/repositories/photo_upload_repository.dart';
import '../features/uploads/domain/services/sequential_photo_upload_source.dart';
import '../features/uploads/presentation/controllers/upload_progress_controller.dart';
import '../features/uploads/presentation/screens/upload_progress_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/capture_session.dart';
import '../screens/model_confirmation_screen.dart';
import '../screens/processing_state.dart';

/// Adapts the production creation result without issuing a create request.
Future<void> openCreatedPhotoScanFlow(
  NavigatorState navigator,
  ScanItem scan,
) async {
  if (scan.inputMode != ScanInputMode.image) return;
  await openCreatedScanFlow(
    navigator,
    ScanModel(
      id: scan.id,
      name: scan.name,
      inputMode: scan.inputMode.name,
      description: scan.description,
      notes: scan.notes,
      fileCount: scan.fileCount,
      totalSizeBytes: scan.totalSizeBytes,
      createdAt: scan.createdAt,
      updatedAt: scan.updatedAt,
    ),
  );
}

Future<void> openCreatedScanFlow(
  NavigatorState navigator,
  ScanModel scan, {
  ValueChanged<PhotoUploadResult>? onUploaded,
  PhotoUploadRepository? repository,
}) async {
  if (repository == null) {
    await navigator.push<void>(
      MaterialPageRoute(
        builder: (_) => CreateModelScreen(scanId: scan.id, scanName: scan.name),
      ),
    );
    return;
  }
  final scanId = await navigator.push<String>(
    MaterialPageRoute<String>(
      builder: (_) => ScanWizardScreen(scanId: scan.id, scan: scan),
    ),
  );
  if (!navigator.mounted || scanId != scan.id || scan.inputMode != 'image') {
    return;
  }
  final uploads = repository;
  final session = CaptureSession(scanId: scanId);
  await navigator.push<void>(
    MaterialPageRoute<void>(
      builder: (_) => PhotoCaptureFlow(
        session: session,
        repository: uploads,
        onUploaded: onUploaded,
      ),
    ),
  );
}

class PhotoCaptureFlow extends StatefulWidget {
  const PhotoCaptureFlow({
    super.key,
    required this.session,
    required this.repository,
    this.onUploaded,
    this.reconstruction,
  });
  final CaptureSession session;
  final PhotoUploadRepository repository;
  final ValueChanged<PhotoUploadResult>? onUploaded;

  /// Starts the backend job (POST /scans/{id}/job); injectable for tests.
  final ReconstructionJobStartRepository? reconstruction;
  @override
  State<PhotoCaptureFlow> createState() => _PhotoCaptureFlowState();
}

class _PhotoCaptureFlowState extends State<PhotoCaptureFlow> {
  SequentialPhotoUploadSource? _source;
  UploadProgressController? _controller;
  CaptureSession? _frozenView;
  bool _routeOpen = false;

  Future<void> _upload(BuildContext context, CaptureSession session) async {
    if (_routeOpen || session.scanId == null || !session.canReview) return;
    _routeOpen = true;
    try {
      if (_source == null) {
        final manifest = PhotoUploadManifest(
          id: 'upload-${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}',
          scanId: session.scanId!,
          items: [
            for (final entry in session.photoEntries)
              PhotoUploadItem(
                localCaptureId: entry.localCaptureId,
                file: LocalPhotoFile(
                  entry.file.path,
                  filename: entry.file.name,
                  mimeType: entry.file.mimeType,
                ),
              ),
          ],
        );
        _frozenView = CaptureSession(scanId: session.scanId)
          ..detailLevel = session.detailLevel;
        for (final entry in session.photoEntries) {
          _frozenView!.addPhoto(entry.file);
        }
        _source = SequentialPhotoUploadSource(
          manifest: manifest,
          repository: widget.repository,
        );
        _controller = UploadProgressController(source: _source!);
      }
      final route = Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AnimatedBuilder(
            animation: _controller!,
            builder: (_, _) => PopScope(
              canPop: ![
                UploadProgressStatus.uploading,
                UploadProgressStatus.preparing,
                UploadProgressStatus.reconciling,
              ].contains(_controller!.state.status),
              child: UploadProgressScreen(
                controller: _controller!,
                session: _frozenView!,
                photoUpload: true,
                onUploadCompleted: () {
                  final result = _source!.result;
                  if (mounted && result != null) {
                    widget.onUploaded?.call(result);
                    // Uploaded photos feed the reconstruction confirmation step.
                    unawaited(
                      Navigator.of(context).pushReplacement<void, void>(
                        MaterialPageRoute<void>(
                          builder: (_) => ModelConfirmationScreen(
                            session: _frozenView!,
                            onSubmit: (_) => _startReconstruction(result),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      );
      unawaited(_source!.start());
      await route;
    } finally {
      _routeOpen = false;
    }
  }

  /// The backend pipeline reconstructs from one uploaded image.
  Future<ProcessingSnapshot> _startReconstruction(
    PhotoUploadResult result,
  ) async {
    final images = [for (final photo in result.photos) photo.image];
    if (images.isEmpty) throw StateError('No uploaded image to reconstruct');
    final input = images.firstWhere(
      (image) => !image.isExcluded,
      orElse: () => images.first,
    );
    final repository =
        widget.reconstruction ??
        ReconstructionJobStartRepositoryImpl(
          ReconstructionJobStartApi(ApiClient()),
        );
    try {
      await repository.startJob(scanId: result.scanId, inputImageId: input.id);
    } on ReconstructionStartFailure catch (startFailure) {
      // An ambiguous start (or a repeated tap) may already have queued a job;
      // follow it instead of failing. Otherwise surface the start failure.
      try {
        await repository.getLatestJob(scanId: result.scanId);
      } catch (_) {
        throw startFailure;
      }
    }
    return const ProcessingSnapshot.waiting();
  }

  @override
  Widget build(BuildContext context) =>
      CameraScreen(session: widget.session, onUpload: _upload);
  @override
  void dispose() {
    _controller?.dispose();
    if (_source != null) unawaited(_source!.dispose());
    super.dispose();
  }
}
