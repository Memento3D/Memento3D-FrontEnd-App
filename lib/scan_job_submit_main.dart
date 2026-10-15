import 'package:flutter/material.dart';
import 'package:memento3d_frontend_app/core/theme/app_theme.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_model.dart';
import 'package:memento3d_frontend_app/features/scans/data/repositories/scan_repository.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/scan_service.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/scan_job_submit_screen.dart';

/// Isolated preview entry for [ScanJobSubmitScreen] only — no login, no
/// dashboard, no wizard, and no real backend call.
///
/// Run with:
///   flutter run -t lib/scan_job_submit_main.dart -d chrome
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Never hits the network: POST /scans/{id}/job is faked in-memory.
  ScanRepository.instance.setService(_FakeScanService());
  runApp(const _PreviewApp());
}

class _FakeScanService extends ScanService {
  @override
  Future<ReconstructionJobModel> createReconstructionJob(String scanId) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return ReconstructionJobModel(
      jobId: 'preview-job-1',
      scanId: scanId,
      queuePosition: 3,
    );
  }
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();

  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp> {
  int? _qualityScore = 92;

  ScanItem get _scan => ScanItem(
    id: 'scan-preview-1',
    name: 'Búp bê gỗ kỷ niệm',
    inputMode: ScanInputMode.image,
    status: ScanItemStatus.ready,
    fileCount: 48,
    totalSizeBytes: 1024 * 1024 * 180,
    createdAt: DateTime.now(),
    qualityScore: _qualityScore,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scan Job Submit Preview',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: Column(
          children: [
            _presetSwitcher(),
            Expanded(
              child: ScanJobSubmitScreen(
                // Rebuild with a new key so the screen's local state
                // (submitting/error) resets whenever the preset changes.
                key: ValueKey(_qualityScore),
                scan: _scan,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetSwitcher() {
    return SafeArea(
      bottom: false,
      child: Container(
        color: const Color(0xFFF3F4F6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          children: [
            _presetChip('Tốt (95)', 95),
            _presetChip('Cảnh báo (65)', 65),
            _presetChip('Chặn (30)', 30),
            _presetChip('Không có score', null),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, int? score) {
    return ChoiceChip(
      label: Text(label),
      selected: _qualityScore == score,
      onSelected: (_) => setState(() => _qualityScore = score),
    );
  }
}
