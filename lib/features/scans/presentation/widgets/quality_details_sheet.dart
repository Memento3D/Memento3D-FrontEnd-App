import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/quality_report.dart';
import 'quality_photo_section.dart';
import 'quality_report_presentation.dart';

Future<void> showQualityDetailsSheet({
  required BuildContext context,
  required QualityReport report,
  ValueChanged<QualityPhotoResult>? onPhotoSelected,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: QualityReportColors.background,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: FractionallySizedBox(
      heightFactor: 0.9,
      child: QualityDetailsSheet(
        report: report,
        onPhotoSelected: onPhotoSelected,
      ),
    ),
  ),
);

class QualityDetailsSheet extends StatelessWidget {
  const QualityDetailsSheet({
    super.key,
    required this.report,
    this.onPhotoSelected,
  });
  final QualityReport report;
  final ValueChanged<QualityPhotoResult>? onPhotoSelected;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IconButton(
                key: const Key('quality-details-close'),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('quality-details-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      strings.qualityReportDetailsTitle,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  QualityPhotoSection(
                    report: report,
                    onPhotoSelected: onPhotoSelected,
                  ),
                  const SizedBox(height: 16),
                  QualityReportCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            strings.qualityReportSuggestionTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          report.suggestion,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(height: 1.6),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
