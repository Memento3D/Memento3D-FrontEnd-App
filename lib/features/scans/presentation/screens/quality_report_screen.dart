import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/quality_report.dart';
import '../widgets/quality_report_presentation.dart';
import '../widgets/quality_photo_summary.dart';
import '../widgets/quality_details_sheet.dart';
import '../widgets/quality_score_gauge.dart';

/// Supplied-data presentation only; fetching and workflow actions belong upstream.
class QualityReportScreen extends StatelessWidget {
  const QualityReportScreen({
    super.key,
    required this.report,
    this.onPhotoSelected,
    this.onStartReconstruction,
    this.onRecoverPhotos,
  });
  final QualityReport report;
  final ValueChanged<QualityPhotoResult>? onPhotoSelected;
  final VoidCallback? onStartReconstruction;
  final VoidCallback? onRecoverPhotos;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context).textTheme;
    final accent = QualityReportColors.accent(report.category);
    final category = QualityReportColors.label(report.category, strings);
    return Scaffold(
      backgroundColor: QualityReportColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: strings.back,
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: IconButton.styleFrom(
                          backgroundColor: QualityReportColors.lavender,
                          foregroundColor: QualityReportColors.primary,
                        ),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          strings.qualityReportTitle,
                          style: theme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: QualityReportColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  QualityReportCard(
                    child: Column(
                      children: [
                        Text(
                          strings.qualityReportScanQuality,
                          textAlign: TextAlign.center,
                          style: theme.titleMedium?.copyWith(
                            color: QualityReportColors.muted,
                          ),
                        ),
                        const SizedBox(height: 16),
                        QualityScoreGauge(
                          score: report.overallScore,
                          category: report.category,
                        ),
                        const SizedBox(height: 12),
                        Semantics(
                          label: category,
                          child: ExcludeSemantics(
                            child: Container(
                              key: const Key('quality-report-category'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.09),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    QualityReportColors.icon(report.category),
                                    color: accent,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      category,
                                      style: theme.titleMedium?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (report.support ==
                            QualityReportSupport.eligible) ...[
                          const SizedBox(height: 12),
                          Text(
                            strings.qualityReportEligible,
                            textAlign: TextAlign.center,
                            style: theme.bodyMedium?.copyWith(
                              color: QualityReportColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  QualityPhotoSummary(
                    report: report,
                    onViewDetails: () => showQualityDetailsSheet(
                      context: context,
                      report: report,
                      onPhotoSelected: onPhotoSelected,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('quality-report-start-reconstruction'),
                    onPressed: report.category == QualityCategory.green
                        ? onStartReconstruction
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: QualityReportColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE8E2EF),
                      disabledForegroundColor: const Color(0xFF716879),
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      strings.qualityReportStartReconstruction,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (report.category != QualityCategory.green) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      key: const ValueKey('quality-report-recover-photos'),
                      onPressed: onRecoverPhotos,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: QualityReportColors.primary,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(
                        strings.qualityReportRecoverPhotos,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
