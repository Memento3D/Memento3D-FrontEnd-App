import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../controllers/model_viewer_controller.dart';

/// Flutter overlays only; existing controller owns all rendering commands.
class ModelViewerToolbar extends StatelessWidget {
  const ModelViewerToolbar({
    super.key,
    required this.controller,
    this.showHint = true,
  });
  final ModelViewerController controller;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final modes = Material(
          color: colors.surface.withValues(alpha: .94),
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Wrap(
              spacing: 2,
              children: [
                for (final mode in DisplayMode.values)
                  ChoiceChip(
                    key: ValueKey('viewer-${mode.name}'),
                    label: Text(
                      mode == DisplayMode.shaded
                          ? strings.modelViewerShaded
                          : strings.modelViewerWireframe,
                    ),
                    selected: controller.displayMode == mode,
                    showCheckmark: false,
                    side: BorderSide.none,
                    shape: shape,
                    selectedColor: colors.primary,
                    backgroundColor: Colors.transparent,
                    labelStyle: TextStyle(
                      color: controller.displayMode == mode
                          ? colors.onPrimary
                          : colors.onSurfaceVariant,
                    ),
                    onSelected: controller.controlsEnabled
                        ? (_) => controller.setDisplayMode(mode)
                        : null,
                  ),
              ],
            ),
          ),
        );
        final actions = Wrap(
          spacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilterChip(
              key: const ValueKey('viewer-grid'),
              avatar: Icon(
                Icons.grid_4x4,
                size: 18,
                color: controller.gridVisible
                    ? colors.onPrimary
                    : colors.onSurfaceVariant,
              ),
              label: Text(strings.modelViewerGrid),
              selected: controller.gridVisible,
              showCheckmark: false,
              shape: shape,
              side: BorderSide.none,
              selectedColor: colors.primary,
              backgroundColor: colors.surface.withValues(alpha: .94),
              labelStyle: TextStyle(
                color: controller.gridVisible
                    ? colors.onPrimary
                    : colors.onSurfaceVariant,
              ),
              onSelected: controller.controlsEnabled
                  ? controller.setGridVisible
                  : null,
            ),
            IconButton.filledTonal(
              key: const ValueKey('viewer-reset'),
              tooltip: strings.modelViewerReset,
              style: IconButton.styleFrom(
                backgroundColor: colors.surface.withValues(alpha: .94),
              ),
              onPressed: controller.controlsEnabled
                  ? controller.resetView
                  : null,
              icon: const Icon(Icons.restart_alt),
            ),
          ],
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Reflow controls rather than shrink text or cover the whole canvas.
                final labels = TextPainter(
                  text: TextSpan(
                    text:
                        '${strings.modelViewerShaded}${strings.modelViewerWireframe}${strings.modelViewerGrid}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                )..layout();
                final requiredWidth = labels.width + 196;
                labels.dispose();
                if (constraints.maxWidth < requiredWidth ||
                    MediaQuery.textScalerOf(context).scale(14) > 21) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: modes,
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: actions,
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [modes, actions],
                );
              },
            ),
            if (showHint) ...[
              const SizedBox(height: 4),
              Text(
                strings.modelViewerInteractionHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ],
        );
      },
    );
  }
}
