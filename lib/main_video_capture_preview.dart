import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/camera_view.dart';
import 'screens/capture_mode.dart';
import 'screens/capture_session.dart';
import 'screens/capture_wizard.dart';

/// Development-only entry point. No authentication, device camera, or network.
void main() => runApp(const VideoCapturePreviewApp());

class VideoCapturePreviewApp extends StatefulWidget {
  const VideoCapturePreviewApp({super.key});

  @override
  State<VideoCapturePreviewApp> createState() => _VideoCapturePreviewAppState();
}

class _VideoCapturePreviewAppState extends State<VideoCapturePreviewApp> {
  final _session = CaptureSession();
  CaptureMode _mode = CaptureMode.photo;
  Locale _locale = const Locale('vi');

  @override
  void initState() {
    super.initState();
    // Local fixture entries exercise the real count and thumbnail fallback.
    // No files are created and no capture or library selection is simulated.
    for (var i = 0; i < 5; i++) {
      _session.addPhoto(XFile(''));
    }
  }

  void _openDev(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DEVELOPMENT PREVIEW'),
              const SizedBox(height: 8),
              const Text(
                'Fixed camera frame · 5 photo fixtures · no capture or upload',
              ),
              TextButton(
                key: const Key('video-preview-language'),
                onPressed: () {
                  setState(
                    () => _locale = Locale(
                      _locale.languageCode == 'vi' ? 'en' : 'vi',
                    ),
                  );
                  Navigator.pop(sheetContext);
                },
                child: const Text('EN / VI'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: Text(AppLocalizations.of(sheetContext)!.closePreview),
              ),
            ],
          ),
        ),
      ),
    );
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
    home: Builder(
      builder: (context) => Stack(
        children: [
          CameraView(
            controller: null,
            previewFrame: const _PreviewFrame(),
            capturedPhotos: _session.capturedPhotos,
            wizardState: CaptureWizardState.ready,
            capturing: false,
            cameraFailed: false,
            mode: _mode,
            onModeChanged: (mode) => setState(() => _mode = mode),
            onCapture: () {},
            onRetry: () {},
            // Inspect the eligible Done appearance without introducing routing.
            onDone: () {},
          ),
          Positioned(
            left: 4,
            top: MediaQuery.paddingOf(context).top + 64,
            child: TextButton(
              key: const Key('video-preview-dev'),
              onPressed: () => _openDev(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFEDE7F6),
                minimumSize: const Size(40, 30),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(fontSize: 10),
              ),
              child: const Text('DEV'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame();

  @override
  Widget build(BuildContext context) => const DecoratedBox(
    key: Key('video-preview-frame'),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE4D9D0), Color(0xFFC5B3AA)],
      ),
    ),
    child: Center(
      child: Icon(Icons.coffee_outlined, size: 100, color: Color(0xFF69554D)),
    ),
  );
}
