// Isolated development entrypoint. No local model is required or bundled.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/model_viewer/presentation/models/model_viewer_data.dart';
import 'features/model_viewer/presentation/screens/model_viewer_screen.dart';
import 'l10n/app_localizations.dart';

void main() => runApp(const _ViewerPreview());

class _ViewerPreview extends StatelessWidget {
  const _ViewerPreview();

  // Optional caller-owned HTTPS GLB; it must allow CORS from the viewer origin.
  static const _modelUrl = String.fromEnvironment('VIEWER_MODEL_URL');

  @override
  Widget build(BuildContext context) => MaterialApp(
    // Platform typography avoids fetching a font for this isolated preview.
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
    home: Builder(
      builder: (context) => ModelViewerScreen(
        enableDiagnostics: const bool.fromEnvironment('VIEWER_DIAGNOSTICS'),
        modelUrl: _modelUrl.isEmpty ? null : _modelUrl,
        // Explicit mock host facts, not measurements or reconstruction results.
        data: ModelViewerData(
          modelName: AppLocalizations.of(context)!.modelViewerPreviewTitle,
          referenceCode: 'DEV-051-UI',
          availability: _modelUrl.isEmpty
              ? ModelAvailability.unavailable
              : ModelAvailability.ready,
          format: _modelUrl.isEmpty ? null : ModelFileFormat.glb,
        ),
        onContinue: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.modelViewerPreviewAction,
            ),
          ),
        ),
      ),
    ),
  );
}
