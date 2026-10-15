/// Development-only preview: flutter run -t lib/main_quality_report_preview.dart
library;

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/scans/presentation/fixtures/quality_report_fixtures.dart';
import 'features/scans/presentation/screens/quality_report_screen.dart';
import 'l10n/app_localizations.dart';

void main() => runApp(const _Preview());

class _Preview extends StatefulWidget {
  const _Preview();
  @override
  State<_Preview> createState() => _PreviewState();
}

class _PreviewState extends State<_Preview> {
  int _selected = 0;
  bool _vietnamese = true;
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    locale: Locale(_vietnamese ? 'vi' : 'en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      bottomNavigationBar: SafeArea(
        child: Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (final (index, label) in ['Green', 'Amber', 'Red'].indexed)
              TextButton(
                onPressed: () => setState(() => _selected = index),
                child: Text(label),
              ),
            TextButton(
              onPressed: () => setState(() => _vietnamese = !_vietnamese),
              child: const Text('EN / VI'),
            ),
          ],
        ),
      ),
      body: QualityReportScreen(
        onStartReconstruction: () =>
            debugPrint('Preview: Green reconstruction callback only.'),
        onRecoverPhotos: () =>
            debugPrint('Preview: Red photo-recovery callback only.'),
        onPhotoSelected: (photo) =>
            debugPrint('Preview photo selected: ${photo.id}'),
        report: [
          QualityReportFixtures.green,
          QualityReportFixtures.amber,
          QualityReportFixtures.red,
        ][_selected],
      ),
    ),
  );
}
