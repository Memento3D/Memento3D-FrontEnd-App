// Isolated development entry point for the production 3D Model Viewer flow.
// Loads the primary GLB from the real backend model_outputs endpoint.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/model_viewer/presentation/screens/model_viewer_screen.dart';
import 'l10n/app_localizations.dart';

void main() => runApp(const _ViewerPreview());

class _ViewerPreview extends StatelessWidget {
  const _ViewerPreview();

  static const _scanId = String.fromEnvironment('VIEWER_SCAN_ID');
  static const _scanName = String.fromEnvironment('VIEWER_SCAN_NAME');

  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: ThemeData(useMaterial3: true),
    debugShowCheckedModeBanner: false,
    locale: const Locale(
      String.fromEnvironment('VIEWER_LOCALE', defaultValue: 'en'),
    ),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: _scanId.isEmpty
        ? const Scaffold(
            body: Center(
              child: Text('Define --dart-define=VIEWER_SCAN_ID=<scan id>'),
            ),
          )
        : ModelViewerScreen(
            scanId: _scanId,
            scanName: _scanName.isEmpty ? null : _scanName,
          ),
  );
}
