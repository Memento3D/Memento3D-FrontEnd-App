import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum CaptureDestination { collection, prints, camera, studio, settings }

/// Presentation only. The caller supplies callbacks for available destinations.
class CaptureBottomNavigation extends StatelessWidget {
  const CaptureBottomNavigation({super.key, this.callbacks = const {}});

  final Map<CaptureDestination, VoidCallback> callbacks;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final labels = [
      strings.captureCollection,
      strings.capturePrints,
      strings.captureCamera,
      strings.captureStudio,
      strings.captureSettings,
    ];
    const icons = [
      Icons.collections_outlined,
      Icons.print_outlined,
      Icons.camera_alt_outlined,
      Icons.auto_awesome_outlined,
      Icons.settings_outlined,
    ];
    return Material(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (final destination in CaptureDestination.values)
                Expanded(
                  child: Semantics(
                    key: ValueKey('capture-nav-${destination.name}'),
                    button: true,
                    selected: destination == CaptureDestination.camera,
                    enabled: callbacks[destination] != null,
                    label: labels[destination.index],
                    child: ExcludeSemantics(
                      child: InkWell(
                        onTap: callbacks[destination],
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (destination == CaptureDestination.camera)
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B4FE8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6B4FE8)
                                          .withValues(alpha: .25),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(
                                icons[destination.index],
                                color: const Color(0xFF716D7B),
                                size: 23,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              labels[destination.index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10,
                                color: destination == CaptureDestination.camera
                                    ? const Color(0xFF6B4FE8)
                                    : const Color(0xFF716D7B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
