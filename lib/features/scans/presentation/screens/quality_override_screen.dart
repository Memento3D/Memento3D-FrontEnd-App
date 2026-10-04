import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/quality_override_context.dart';
import '../../domain/repositories/quality_override_repository.dart';
import '../controllers/quality_override_controller.dart';
import '../controllers/quality_override_state.dart';
import '../widgets/quality_risk_details_sheet.dart';

class QualityOverrideScreen extends StatefulWidget {
  const QualityOverrideScreen({
    super.key,
    required this.context,
    required this.repository,
    required this.onOverrideSuccess,
    required this.onBackToQualityReport,
  });

  final QualityOverrideContext context;
  final QualityOverrideRepository repository;
  final VoidCallback onOverrideSuccess;
  final VoidCallback onBackToQualityReport;

  @override
  State<QualityOverrideScreen> createState() => _QualityOverrideScreenState();
}

class _QualityOverrideScreenState extends State<QualityOverrideScreen> {
  late QualityOverrideController _controller;
  final Set<(String, String)> _reportedSuccesses = {};

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    _controller = QualityOverrideController(
      repository: widget.repository,
      context: widget.context,
    );
    _controller.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
    final state = _controller.state;
    if (state.status == QualityOverrideStatus.success &&
        _reportedSuccesses.add((
          state.context.scanId,
          state.context.qualityRunId,
        ))) {
      widget.onOverrideSuccess();
    }
  }

  @override
  void didUpdateWidget(covariant QualityOverrideScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.repository, oldWidget.repository)) {
      _controller.removeListener(_onStateChanged);
      _controller.dispose();
      _createController();
    } else if (!identical(widget.context, oldWidget.context)) {
      _controller.updateContext(widget.context);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final state = _controller.state;
    final input = state.context;
    final rejected = state.status == QualityOverrideStatus.rejected;
    final blocked = state.isBlocked;
    final finished =
        state.status == QualityOverrideStatus.success ||
        state.status == QualityOverrideStatus.completed;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_controller.state.isSubmitting) {
          widget.onBackToQualityReport();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFCFAFF),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          key: const Key('quality-header-back'),
                          tooltip: strings.back,
                          onPressed: state.isSubmitting
                              ? null
                              : widget.onBackToQualityReport,
                          icon: const Icon(Icons.arrow_back, color: qualityInk),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: qualityAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            strings.qualityRiskTitle,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: qualityInk,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Tooltip(
                          message: strings.profile,
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: qualityPurple,
                            child: Icon(
                              Icons.person_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: rejected
                              ? const Color(0xFFFCE9E9)
                              : qualityPeach,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          rejected
                              ? Icons.block_outlined
                              : Icons.warning_amber_rounded,
                          color: rejected
                              ? const Color(0xFFAD3434)
                              : qualityAmber,
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      rejected
                          ? strings.qualityBlockedStatus
                          : blocked
                          ? strings.qualityIneligibleStatus
                          : finished
                          ? strings.qualityConfirmedStatus
                          : strings.qualityNeedsConfirmation,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: rejected
                            ? const Color(0xFFAD3434)
                            : qualityAmber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rejected
                          ? strings.qualityRejectedTitle
                          : blocked
                          ? strings.qualityIneligibleTitle
                          : finished
                          ? strings.qualityConfirmedTitle
                          : strings.qualityHeroTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: qualityInk,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      rejected
                          ? strings.qualityRejectedBody
                          : blocked
                          ? strings.qualityIneligibleBody
                          : finished
                          ? strings.qualityConfirmedBody
                          : strings.qualityHeroBody,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF665F78),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: qualityLavender,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE6DFFF)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            strings.qualitySummaryTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: qualityInk,
                            ),
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final metrics = [
                                _Metric(
                                  value: '${input.qualifiedImageCount}',
                                  label: strings.qualityQualified,
                                ),
                                _Metric(
                                  value: '${input.affectedImageCount}',
                                  label: strings.qualityNeedsAttention,
                                ),
                                _Metric(
                                  value: strings.qualityPercentage(
                                    input.overallQualityPercentage
                                        .toStringAsFixed(0),
                                  ),
                                  label: strings.qualityOverallScore,
                                ),
                              ];
                              if (constraints.maxWidth < 280 ||
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      22) {
                                return Wrap(
                                  spacing: 20,
                                  runSpacing: 16,
                                  children: metrics,
                                );
                              }
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: metrics
                                    .map((metric) => Expanded(child: metric))
                                    .toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    if (!blocked && !finished) ...[
                      const SizedBox(height: 16),
                      Material(
                        color: qualityPeach,
                        borderRadius: BorderRadius.circular(18),
                        child: Semantics(
                          button: true,
                          enabled: !state.isSubmitting,
                          child: InkWell(
                            key: const Key('quality-caution-card'),
                            borderRadius: BorderRadius.circular(18),
                            onTap: state.isSubmitting
                                ? null
                                : () => showQualityRiskDetailsSheet(
                                    context: context,
                                    controller: _controller,
                                  ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: qualityAmber,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              strings.qualityReviewImages(
                                                input.affectedImageCount,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: qualityInk,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFE1BC),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                strings.qualityNeedsAttention,
                                                style: const TextStyle(
                                                  color: qualityAmber,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(strings.qualityViewDetails),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: qualityAmber,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (state.status ==
                        QualityOverrideStatus.recoverableFailure) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          strings.qualityRecoverableFailure,
                          style: const TextStyle(color: qualityAmber),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (!blocked && !finished)
                      Semantics(
                        liveRegion: state.isSubmitting,
                        child: FilledButton(
                          key: const Key('quality-main-cta'),
                          onPressed: state.canSubmit
                              ? _controller.submit
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: qualityPurple,
                            disabledBackgroundColor: const Color(0xFFE7E0F3),
                            disabledForegroundColor: const Color(0xFF756B88),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 18,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (state.isSubmitting) ...[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: qualityPurple,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Flexible(
                                child: Text(
                                  state.isSubmitting
                                      ? strings.qualitySubmitting
                                      : state.status ==
                                            QualityOverrideStatus
                                                .recoverableFailure
                                      ? strings.qualityRetry
                                      : strings.qualityContinue,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('quality-back-to-report'),
                      onPressed: state.isSubmitting
                          ? null
                          : widget.onBackToQualityReport,
                      style: TextButton.styleFrom(
                        foregroundColor: qualityPurple,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 12,
                        ),
                      ),
                      child: Text(
                        blocked
                            ? strings.qualityBackToReport
                            : strings.qualityBackToImages,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: qualityPurple,
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Color(0xFF665F78))),
    ],
  );
}
