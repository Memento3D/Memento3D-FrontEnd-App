import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/reconstruction_summary.dart';

/// Independent confirmation UI. The caller owns submission and onward navigation.
class ReconstructionConfirmationScreen extends StatefulWidget {
  const ReconstructionConfirmationScreen({
    super.key,
    required this.summary,
    required this.onSubmit,
    required this.onSubmissionSuccess,
  });

  final ReconstructionSummary summary;
  final Future<void> Function(ReconstructionSummary summary) onSubmit;
  final VoidCallback onSubmissionSuccess;

  @override
  State<ReconstructionConfirmationScreen> createState() =>
      _ReconstructionConfirmationScreenState();
}

class _ReconstructionConfirmationScreenState
    extends State<ReconstructionConfirmationScreen> {
  bool _isSubmitting = false;
  bool _submitted = false;
  bool _submissionFailed = false;

  Future<void> _submit() async {
    if (_isSubmitting || _submitted) return;
    setState(() {
      _isSubmitting = true;
      _submissionFailed = false;
    });
    try {
      await widget.onSubmit(widget.summary);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submissionFailed = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _submitted = true;
    });
    widget.onSubmissionSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final summary = widget.summary;
    final amber = summary.qualityStatus == ReconstructionQualityStatus.amber;
    final qualityColor = amber
        ? AppColors.badgeAmberText
        : AppColors.badgeGreenText;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: strings.back,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      strings.reconstructionConfirmationTitle,
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.badgePurpleBg,
                  child: Icon(
                    Icons.view_in_ar_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.reconstructionConfirmationHero,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.reconstructionConfirmationSubtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _metric(
                      strings.reconstructionQualifiedCount(
                        summary.qualifiedImageCount,
                      ),
                      strings.reconstructionQualifiedImages,
                      Icons.photo_library_outlined,
                    ),
                    const Divider(height: 28, color: AppColors.cardBorder),
                    _metric(
                      strings.reconstructionQualityScore(summary.qualityScore),
                      strings.reconstructionQualityLabel,
                      Icons.verified_outlined,
                      color: qualityColor,
                      badge: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: amber
                              ? AppColors.badgeAmberBg
                              : AppColors.badgeGreenBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          amber
                              ? strings.reconstructionQualityAmber
                              : strings.reconstructionQualityGreen,
                          style: textTheme.labelLarge?.copyWith(
                            color: qualityColor,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 28, color: AppColors.cardBorder),
                    _metric(
                      strings.reconstructionEstimatedMinutes(
                        (summary.estimatedProcessingTime.inSeconds / 60).ceil(),
                      ),
                      strings.reconstructionEstimatedTime,
                      Icons.schedule_outlined,
                    ),
                  ],
                ),
              ),
              if (amber) ...[
                const SizedBox(height: 16),
                _notice(
                  key: const ValueKey('reconstructionAmberReminder'),
                  title: strings.reconstructionAmberReminderTitle,
                  body: strings.reconstructionAmberReminderBody,
                  icon: Icons.info_outline,
                  background: AppColors.badgeAmberBg,
                  foreground: AppColors.badgeAmberText,
                ),
              ],
              const SizedBox(height: 20),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.reconstructionProcessTitle,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _processStep(
                      Icons.photo_library_outlined,
                      strings.reconstructionProcessImages,
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_downward,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    _processStep(
                      Icons.cloud_outlined,
                      strings.reconstructionProcessCloud,
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_downward,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    _processStep(
                      Icons.view_in_ar_outlined,
                      strings.reconstructionProcessModel,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.reconstructionProcessBody,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _notice(
                title: strings.reconstructionResourceTitle,
                body: strings.reconstructionResourceBody,
                icon: Icons.info_outline,
                background: AppColors.badgePurpleBg,
                foreground: AppColors.primaryDark,
              ),
              const SizedBox(height: 24),
              if (_submissionFailed) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    strings.reconstructionSubmissionError,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isSubmitting || _submitted ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (_isSubmitting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    Text(
                      _isSubmitting
                          ? strings.reconstructionSubmitting
                          : _submitted
                          ? strings.reconstructionSubmitted
                          : strings.reconstructionStart,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.inputBorder),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  strings.reconstructionBackToReview,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.cardBorder),
      borderRadius: BorderRadius.circular(22),
    ),
    child: child,
  );

  Widget _metric(
    String value,
    String label,
    IconData icon, {
    Color color = AppColors.primary,
    Widget? badge,
  }) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: color),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w700),
                ),
                ?badge,
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _processStep(IconData icon, String label) => Row(
    children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(child: Text(label)),
    ],
  );

  Widget _notice({
    Key? key,
    required String title,
    required String body,
    required IconData icon,
    required Color background,
    required Color foreground,
  }) => Container(
    key: key,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(color: foreground, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: foreground),
        ),
      ],
    ),
  );
}
