import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/uploads/development/manual_upload_progress_source.dart';
import 'features/uploads/domain/models/upload_progress_snapshot.dart';
import 'features/uploads/presentation/controllers/upload_progress_controller.dart';
import 'features/uploads/presentation/screens/upload_progress_screen.dart';
import 'l10n/app_localizations.dart';
import 'screens/capture_session.dart';

void main() => runApp(const UploadProgressPreviewApp());

class UploadProgressPreviewApp extends StatefulWidget {
  const UploadProgressPreviewApp({super.key});
  @override
  State<UploadProgressPreviewApp> createState() =>
      _UploadProgressPreviewAppState();
}

class _UploadProgressPreviewAppState extends State<UploadProgressPreviewApp> {
  late ManualUploadProgressSource _source;
  late UploadProgressController _controller;
  final _session = CaptureSession();
  Locale _locale = const Locale('vi');
  int _completions = 0;

  @override
  void initState() {
    super.initState();
    // Empty in-memory files intentionally render placeholders, never remote
    // sample photos. Counts and transfer totals are explicit preview fixtures.
    for (var i = 0; i < 50; i++) {
      _session.addPhoto(XFile.fromData(Uint8List(0), name: 'preview-$i'));
    }
    _source = ManualUploadProgressSource();
    _controller = UploadProgressController(source: _source);
  }

  void _show(UploadProgressStatus status) {
    if (_controller.state.status == UploadProgressStatus.completed) {
      final previousSource = _source;
      final previousController = _controller;
      setState(() {
        _source = ManualUploadProgressSource()..show(status);
        _controller = UploadProgressController(source: _source);
      });
      previousController.dispose();
      unawaited(previousSource.dispose());
    } else {
      _source.show(status);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    unawaited(_source.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: _locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    theme: ThemeData(useMaterial3: true, fontFamily: 'PlusJakartaSans'),
    home: Builder(
      builder: (context) => Scaffold(
        body: UploadProgressScreen(
          controller: _controller,
          session: _session,
          objectName: 'Cốc Gốm Thủ Công #01',
          onBack: () => _show(UploadProgressStatus.uploading),
          onUploadCompleted: () => setState(() => _completions++),
        ),
        floatingActionButton: FloatingActionButton.small(
          key: const Key('upload-preview-dev'),
          tooltip: 'DEV · Development preview controls',
          onPressed: () => _openControls(context),
          child: const Icon(Icons.bug_report_outlined),
        ),
      ),
    ),
  );

  void _openControls(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'DEVELOPMENT PREVIEW',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close development controls',
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                'No network or storage · completions: $_completions',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final entry in const {
                    'A · Uploading': UploadProgressStatus.uploading,
                    'B · Network lost': UploadProgressStatus.waitingForNetwork,
                    'C · Reconnecting': UploadProgressStatus.reconciling,
                    'D · Completed': UploadProgressStatus.completed,
                    'E · Error': UploadProgressStatus.recoverableFailure,
                  }.entries)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _show(entry.value);
                      },
                      child: Text(entry.key),
                    ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      setState(() {
                        _locale = Locale(
                          _locale.languageCode == 'vi' ? 'en' : 'vi',
                        );
                      });
                    },
                    child: const Text('EN / VI'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
