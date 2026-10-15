import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Recovery-specific palette; the existing Login/Register theme stays unchanged.
abstract final class RecoveryColors {
  static const background = Color(0xFFFAF9FF);
  static const primary = Color(0xFF4F46E5);
  static const primaryContainer = Color(0xFF7459F7);
  static const light = Color(0xFFE5DEFF);
  static const surface = Color(0xFFF1EBFF);
  static const surfaceLow = Color(0xFFF7F1FF);
  static const text = Color(0xFF1C1831);
  static const secondary = Color(0xFF484555);
  static const error = Color(0xFFBA1A1A);
}

class RecoveryPageShell extends StatelessWidget {
  const RecoveryPageShell({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: RecoveryColors.background,
    body: Column(
      children: [
        Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: RecoveryHeader(title: title),
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class RecoveryHeader extends StatelessWidget {
  const RecoveryHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: AppLocalizations.of(context)!.back,
        onPressed: () => Navigator.of(context).maybePop(),
        color: RecoveryColors.text,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: RecoveryColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      const SizedBox(width: 8),
      const ExcludeSemantics(
        child: Row(
          children: [
            Icon(Icons.circle, size: 6, color: RecoveryColors.primary),
            SizedBox(width: 12),
            Icon(Icons.person_outline_rounded, color: RecoveryColors.primary),
          ],
        ),
      ),
    ],
  );
}

class RecoveryHero extends StatelessWidget {
  const RecoveryHero({super.key, this.icon = Icons.lock_reset_rounded});

  final IconData icon;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 176,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -0.12,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: RecoveryColors.light,
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.08,
            child: Container(
              width: 104,
              height: 100,
              decoration: BoxDecoration(
                color: RecoveryColors.primaryContainer,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: RecoveryColors.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 56, color: AppColors.surface),
            ),
          ),
          const Positioned(
            top: 8,
            right: 12,
            child: Icon(
              Icons.auto_awesome,
              size: 22,
              color: RecoveryColors.primary,
            ),
          ),
          const Positioned(
            left: 12,
            bottom: 22,
            child: Icon(
              Icons.circle,
              size: 8,
              color: RecoveryColors.primaryContainer,
            ),
          ),
        ],
      ),
    ),
  );
}

class RecoveryStepIndicator extends StatelessWidget {
  const RecoveryStepIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final vi = Localizations.localeOf(context).languageCode == 'vi';
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              Icon(
                Icons.check_circle,
                size: 15,
                color: i < 2 ? const Color(0xFF008C60) : RecoveryColors.primary,
              ),
              if (i < 2)
                Container(width: 24, height: 2, color: const Color(0xFF008C60)),
            ],
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: RecoveryColors.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            vi ? 'BƯỚC 03 / 03' : 'STEP 03 / 03',
            style: const TextStyle(
              color: RecoveryColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class RecoveryPrimaryButton extends StatelessWidget {
  const RecoveryPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.trailingArrow = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool trailingArrow;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: RecoveryColors.primary,
      foregroundColor: AppColors.surface,
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    ),
    child: trailingArrow
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(label, textAlign: TextAlign.center)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          )
        : Text(label, textAlign: TextAlign.center),
  );
}
