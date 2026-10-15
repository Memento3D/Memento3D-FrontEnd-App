/// Development-only entry point. Run with:
/// flutter run -t lib/main_quality_override_preview.dart
library;

import 'dart:async';

import 'package:flutter/material.dart';

import 'features/scans/domain/models/quality_override_context.dart';
import 'features/scans/domain/models/quality_override_outcome.dart';
import 'features/scans/domain/repositories/quality_override_repository.dart';
import 'features/scans/presentation/screens/quality_override_screen.dart';
import 'l10n/app_localizations.dart';

void main() => runApp(const _QualityOverridePreview());

const _previewContext = QualityOverrideContext(
  scanId: 'preview-scan',
  qualityRunId: 'preview-quality-run',
  classification: QualityClassification.amber,
  qualifiedImageCount: 42,
  affectedImageCount: 6,
  overallQualityPercentage: 78,
);

/// Local manual completion only. Never used by the production entry point.
class _PreviewQualityOverrideRepository extends ChangeNotifier
    implements QualityOverrideRepository {
  Completer<QualityOverrideOutcome>? _pending;
  int requestCount = 0;

  bool get hasPendingRequest => _pending != null;

  @override
  Future<QualityOverrideOutcome> requestOverride(
    QualityOverrideContext context,
  ) {
    if (_pending != null) return _pending!.future;
    final request = Completer<QualityOverrideOutcome>();
    _pending = request;
    requestCount++;
    notifyListeners();
    return request.future;
  }

  void complete(QualityOverrideOutcome outcome) {
    final request = _pending;
    if (request == null) return;
    _pending = null;
    request.complete(outcome);
    notifyListeners();
  }
}

class _QualityOverridePreview extends StatefulWidget {
  const _QualityOverridePreview();

  @override
  State<_QualityOverridePreview> createState() =>
      _QualityOverridePreviewState();
}

class _QualityOverridePreviewState extends State<_QualityOverridePreview> {
  late _PreviewQualityOverrideRepository _repository;
  QualityOverrideOutcome _outcome = QualityOverrideOutcome.success;
  Locale _locale = const Locale('vi');
  int _session = 0;
  int _successCallbacks = 0;
  int _backCallbacks = 0;
  String _feedback = 'Local mock only. Acknowledge, then submit.';

  @override
  void initState() {
    super.initState();
    _createRepository();
  }

  void _createRepository() {
    _repository = _PreviewQualityOverrideRepository()
      ..addListener(_onRequestChanged);
  }

  void _onRequestChanged() {
    if (mounted) setState(() {});
  }

  void _reset() {
    if (_repository.hasPendingRequest) return;
    setState(() {
      _repository.removeListener(_onRequestChanged);
      _repository.dispose();
      _createRepository();
      _session++;
      _successCallbacks = 0;
      _backCallbacks = 0;
      _feedback = 'Preview reset. Acknowledge, then submit.';
    });
  }

  void _complete() {
    setState(() => _feedback = 'Local result: ${_outcome.name}.');
    _repository.complete(_outcome);
  }

  @override
  void dispose() {
    _repository.removeListener(_onRequestChanged);
    _repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Quality Override #16 — Development Preview',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B4FE8)),
    ),
    locale: _locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // All preview controls stay outside QualityOverrideScreen.
            Material(
              color: const Color(0xFFF2EEFF),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'DEV PREVIEW #16 • No network or navigation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        PopupMenuButton<QualityOverrideOutcome>(
                          tooltip: 'Choose the next local result',
                          initialValue: _outcome,
                          onSelected: (value) =>
                              setState(() => _outcome = value),
                          itemBuilder: (_) => QualityOverrideOutcome.values
                              .map(
                                (value) => PopupMenuItem(
                                  value: value,
                                  child: Text(value.name),
                                ),
                              )
                              .toList(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text('Result: ${_outcome.name} ▾'),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _locale = Locale(
                              _locale.languageCode == 'vi' ? 'en' : 'vi',
                            );
                          }),
                          child: Text(
                            'Language: ${_locale.languageCode.toUpperCase()}',
                          ),
                        ),
                        TextButton(
                          onPressed: _repository.hasPendingRequest
                              ? null
                              : _reset,
                          child: const Text('Reset demo'),
                        ),
                      ],
                    ),
                    Text(
                      'Requests: ${_repository.requestCount} • Success callbacks: $_successCallbacks • Back callbacks: $_backCallbacks',
                    ),
                    Semantics(liveRegion: true, child: Text(_feedback)),
                    if (_repository.hasPendingRequest)
                      FilledButton(
                        onPressed: _complete,
                        child: const Text('Complete local request'),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: QualityOverrideScreen(
                key: ValueKey(_session),
                context: _previewContext,
                repository: _repository,
                onOverrideSuccess: () => setState(() {
                  _successCallbacks++;
                  _feedback = 'onOverrideSuccess invoked. No #17 navigation.';
                }),
                onBackToQualityReport: () => setState(() {
                  _backCallbacks++;
                  _feedback =
                      'onBackToQualityReport invoked. No #14 navigation.';
                }),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
