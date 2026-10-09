import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/quality_report.dart';
import 'quality_report_presentation.dart';

class QualityPhotoSection extends StatefulWidget {
  const QualityPhotoSection({
    super.key,
    required this.report,
    this.onPhotoSelected,
  });
  final QualityReport report;
  final ValueChanged<QualityPhotoResult>? onPhotoSelected;
  @override
  State<QualityPhotoSection> createState() => _QualityPhotoSectionState();
}

class _QualityPhotoSectionState extends State<QualityPhotoSection> {
  bool _expanded = false;
  @override
  void didUpdateWidget(covariant QualityPhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.report, widget.report)) _expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final report = widget.report;
    // Keep original positions for labels and original objects for callbacks.
    final visible = report.photos.indexed
        .where(
          (entry) =>
              _expanded ||
              entry.$2.status == QualityPhotoStatus.warn ||
              entry.$2.status == QualityPhotoStatus.fail,
        )
        .toList();
    final theme = Theme.of(context).textTheme;
    return QualityReportCard(
      color: QualityReportColors.lavender,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                _expanded
                    ? strings.qualityReportAllPhotos
                    : strings.qualityReportAttentionPhotos,
                style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(strings.qualityReportAttentionPhotoCount(visible.length)),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final columns =
                  ((constraints.maxWidth + 10) / (82 * math.max(1, scale) + 10))
                      .floor()
                      .clamp(1, 3);
              final width =
                  (constraints.maxWidth - (columns - 1) * 10) / columns;
              return Wrap(
                key: const Key('quality-photo-grid'),
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final (index, photo) in visible)
                    SizedBox(
                      width: width,
                      child: QualityPhotoTile(
                        key: ValueKey(photo.id),
                        photo: photo,
                        number: index + 1,
                        onSelected: widget.onPhotoSelected,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const Key('quality-photo-expand'),
            onPressed: () => setState(() => _expanded = !_expanded),
            style: TextButton.styleFrom(
              foregroundColor: QualityReportColors.primary,
            ),
            child: Text(
              _expanded
                  ? strings.qualityReportCollapsePhotos
                  : strings.qualityReportViewAllPhotos(report.photos.length),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class QualityPhotoTile extends StatelessWidget {
  const QualityPhotoTile({
    super.key,
    required this.photo,
    required this.number,
    this.onSelected,
  });
  final QualityPhotoResult photo;
  final int number;
  final ValueChanged<QualityPhotoResult>? onSelected;
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final (label, category) = switch (photo.status) {
      QualityPhotoStatus.pass => (
        strings.qualityReportPass,
        QualityCategory.green,
      ),
      QualityPhotoStatus.warn => (
        strings.qualityReportWarn,
        QualityCategory.amber,
      ),
      QualityPhotoStatus.fail => (
        strings.qualityReportFail,
        QualityCategory.red,
      ),
    };
    final color = QualityReportColors.accent(category);
    final select = onSelected == null ? null : () => onSelected!(photo);
    return Semantics(
      label: '${strings.photoNumber(number)}, $label',
      button: true,
      enabled: select != null,
      onTap: select,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: select,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: color, width: 2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      photo.assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: Colors.white,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(
                              strings.imageUnavailable,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                  child: Column(
                    children: [
                      Text(
                        strings.photoNumber(number),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        QualityReportColors.icon(category),
                        size: 18,
                        color: color,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
