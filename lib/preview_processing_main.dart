import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/scans/data/models/job_model.dart';
import 'features/scans/data/services/job_service.dart';
import 'l10n/app_localizations.dart';
import 'screens/processing_screen.dart';

/// Demo entry point that renders the Processing Progress screen with
/// rotating fake backend job states (no real backend required).
void main() {
  runApp(const PreviewApp());
}

class DemoJobService extends JobService {
  int _tick = 0;

  @override
  Future<JobModel> getScanJob(String scanId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    const stages = [
      'queued',
      'downloading',
      'preprocessing',
      'shape_generation',
      'texturing',
      'validating',
      'exporting',
      'uploading',
      'done',
    ];
    final stage = stages[_tick % stages.length];
    _tick++;
    return JobModel(
      id: 'demo-job',
      scanId: scanId,
      status: JobStatus.fromBackendValue(
        stage == 'done' ? 'done' : 'processing',
      ),
      stage: jobStageFromBackendValue(stage),
      rawStage: stage,
      progress: (_tick % stages.length) / stages.length,
      etaSeconds: 240 - (_tick % stages.length) * 20,
    );
  }
}

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memento3D Processing Preview',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6B4FE8),
      ),
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: ProcessingScreen(
        scanId: 'demo-scan',
        jobService: DemoJobService(),
      ),
    );
  }
}
