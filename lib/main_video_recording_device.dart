import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'screens/camera_screen.dart';
import 'screens/video_recording.dart';

/// Device-only Phase B harness. Uses the real shared camera, without fixtures.
void main() => runApp(const VideoRecordingDeviceApp());

class VideoRecordingDeviceApp extends StatelessWidget {
  const VideoRecordingDeviceApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => CameraScreen(
                  developmentWrapper: (context, diagnostics, capture) =>
                      VideoRecordingDevOverlay(
                        diagnostics: diagnostics,
                        child: capture,
                      ),
                ),
              ),
            ),
            child: const Text('Phase B: Camera'),
          ),
        ),
      ),
    ),
  );
}

/// Only the device entry point installs this decoration.
class VideoRecordingDevOverlay extends StatelessWidget {
  const VideoRecordingDevOverlay({
    super.key,
    required this.diagnostics,
    required this.child,
  });
  final VideoRecordingDiagnostics diagnostics;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      Positioned(
        right: 8,
        top: MediaQuery.paddingOf(context).top + 60,
        child: Material(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          child: TextButton(
            key: const Key('recording-dev-button'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: const Size(48, 32),
            ),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) =>
                  VideoRecordingDiagnosticsPanel(diagnostics: diagnostics),
            ),
            child: const Text('DEV', style: TextStyle(fontSize: 10)),
          ),
        ),
      ),
    ],
  );
}

class VideoRecordingDiagnosticsPanel extends StatelessWidget {
  const VideoRecordingDiagnosticsPanel({super.key, required this.diagnostics});
  final VideoRecordingDiagnostics diagnostics;

  Future<int> _readableLength(LocalVideoSelection video) async {
    final bytes = await video.file.length();
    // Read at most one byte to check access, never load a recording into memory.
    if (bytes > 0) await video.file.openRead(0, 1).first;
    return bytes;
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ListenableBuilder(
        listenable: diagnostics,
        builder: (context, _) {
          final video = diagnostics.videoSession.currentVideo;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('DEV: Phase B recording diagnostics'),
              Text('Recording state: ${diagnostics.state.name}'),
              Text('Selected video: ${video != null}'),
              if (video != null) ...[
                const SizedBox(height: 12),
                Text('Filename: ${video.file.name}'),
                SelectableText('Local path: ${video.file.path}'),
                FutureBuilder<int>(
                  key: ObjectKey(video),
                  future: _readableLength(video),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Text(
                        'Current file check: unavailable (missing or unreadable)',
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Text('Current file check: checking');
                    }
                    return Text(
                      'Current file: exists/readable; byte length: ${snapshot.data}',
                    );
                  },
                ),
                Text('Finalized byte length: ${video.finalizedByteLength}'),
                const Text('File check: exists and non-empty at finalization'),
                Text('Source: ${video.source.name}'),
              ],
            ],
          );
        },
      ),
    ),
  );
}
