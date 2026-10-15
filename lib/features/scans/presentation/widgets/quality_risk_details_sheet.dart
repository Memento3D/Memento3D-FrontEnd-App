import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../l10n/app_localizations.dart';
import '../controllers/quality_override_controller.dart';
import '../controllers/quality_override_state.dart';

const qualityPurple = Color(0xFF6B4FE8);
const qualityLavender = Color(0xFFF2EEFF);
const qualityInk = Color(0xFF29243D);
const qualityPeach = Color(0xFFFFF0DF);
const qualityAmber = Color(0xFF986016);

/// Confirmation records acknowledgement only; no repository request is made.
Future<void> showQualityRiskDetailsSheet({
  required BuildContext context,
  required QualityOverrideController controller,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: const Color(0xFFFCFAFF),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (_) => QualityRiskDetailsSheet(controller: controller),
);

class QualityRiskDetailsSheet extends StatefulWidget {
  const QualityRiskDetailsSheet({super.key, required this.controller});

  final QualityOverrideController controller;

  @override
  State<QualityRiskDetailsSheet> createState() =>
      _QualityRiskDetailsSheetState();
}

class _QualityRiskDetailsSheetState extends State<QualityRiskDetailsSheet> {
  late final _context = widget.controller.state.context;
  late final _revision = widget.controller.contextRevision;
  late bool _checked = switch (widget.controller.state.status) {
    QualityOverrideStatus.acknowledged ||
    QualityOverrideStatus.recoverableFailure => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    // The parent may replace input while this separate modal route is open.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Builder(
      builder: (context) {
        final state = widget.controller.state;
        final current =
            identical(state.context, _context) &&
            widget.controller.contextRevision == _revision;
        final allowed = current && (state.canAcknowledge || state.canSubmit);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.88,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5CDE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.qualityRiskDetailsTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: qualityInk,
                            ),
                          ),
                        ),
                        IconButton(
                          key: const Key('quality-sheet-close'),
                          tooltip: strings.qualityCloseDetails,
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.qualityRiskDetailsSubtitle(
                        _context.affectedImageCount,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(strings.qualityAffectedImages, style: _heading),
                    const SizedBox(height: 12),
                    QualityAffectedImagePlaceholders(
                      count: _context.affectedImageCount,
                    ),
                    const SizedBox(height: 24),
                    Text(strings.qualityImpactTitle, style: _heading),
                    const SizedBox(height: 12),
                    _RiskLine(
                      icon: Icons.blur_on,
                      text: strings.qualitySurfaceRisk,
                    ),
                    const SizedBox(height: 12),
                    _RiskLine(
                      icon: Icons.view_in_ar_outlined,
                      text: strings.qualityGeometryRisk,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: qualityLavender,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(strings.qualityReassurance),
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    CheckboxListTile(
                      key: const Key('quality-acknowledgement'),
                      value: _checked,
                      onChanged: allowed
                          ? (value) => setState(() => _checked = value ?? false)
                          : null,
                      activeColor: qualityPurple,
                      contentPadding: EdgeInsets.zero,
                      minTileHeight: 48,
                      visualDensity: VisualDensity.standard,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        strings.qualityAcknowledgement,
                        key: const Key('quality-acknowledgement-label'),
                      ),
                    ),
                    Text(strings.qualityAcknowledgementHint),
                    if (!current) ...[
                      const SizedBox(height: 8),
                      Text(strings.qualityContextChanged),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const Key('quality-sheet-confirm'),
                      onPressed: _checked && allowed
                          ? () {
                              // Recheck synchronously against the current input.
                              if (!identical(
                                    widget.controller.state.context,
                                    _context,
                                  ) ||
                                  widget.controller.contextRevision !=
                                      _revision) {
                                return;
                              }
                              widget.controller.acknowledge();
                              Navigator.pop(context);
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: qualityPurple,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 20,
                        ),
                      ),
                      child: Text(
                        strings.qualityRiskTitle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

const _heading = TextStyle(
  fontSize: 17,
  fontWeight: FontWeight.w700,
  color: qualityInk,
);

class _RiskLine extends StatelessWidget {
  const _RiskLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: qualityAmber, size: 24),
      const SizedBox(width: 12),
      Expanded(child: Text(text)),
    ],
  );
}

/// No image paths are supplied by the current domain input. Never fetch samples.
class QualityAffectedImagePlaceholders extends StatelessWidget {
  const QualityAffectedImagePlaceholders({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    if (count <= 0) return Text(strings.qualityNoAffectedImages);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(count.clamp(0, 3), (index) {
        final remaining = count > 3 && index == 2;
        final label = remaining
            ? '+${count - 2}'
            : strings.photoNumber(index + 1);
        return Semantics(
          label: remaining
              ? strings.qualityAdditionalAffectedImages(count - 2)
              : '$label. ${strings.imageUnavailable}',
          child: ExcludeSemantics(
            child: Container(
              key: ValueKey('quality-image-placeholder-$index'),
              width: 84,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
              decoration: BoxDecoration(
                color: qualityLavender,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6DFFF)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.image_outlined, color: qualityPurple),
                  const SizedBox(height: 6),
                  Text(label, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
