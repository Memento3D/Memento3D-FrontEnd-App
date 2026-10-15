import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'capture_mode.dart';

class CaptureModeSwitcher extends StatelessWidget {
  const CaptureModeSwitcher({super.key, required this.mode, this.onChanged});

  final CaptureMode mode;
  final ValueChanged<CaptureMode>? onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EEFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final choice in CaptureMode.values)
            Semantics(
              key: ValueKey('capture-mode-${choice.name}'),
              button: true,
              selected: mode == choice,
              enabled: onChanged != null,
              child: Material(
                color: mode == choice
                    ? const Color(0xFF6B4FE8)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: onChanged == null ? null : () => onChanged!(choice),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Text(
                      choice == CaptureMode.photo
                          ? strings.photo
                          : strings.video,
                      style: TextStyle(
                        color: mode == choice
                            ? Colors.white
                            : const Color(0xFF29243D),
                        fontSize: 12,
                        fontWeight: mode == choice
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
