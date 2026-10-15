import 'package:flutter/material.dart';

/// Material 3 motion tokens: durations and curves shared by all transitions.
///
/// Values follow the Material 3 motion guideline (short/medium emphasized
/// durations, standard/emphasized easing) so future animated components stay
/// visually consistent instead of each picking its own numbers.
class AppMotion {
  const AppMotion._();

  /// Shortest transition duration. Use for small, local state changes such as
  /// icon toggles, ripple feedback, or a chip selecting/deselecting.
  static const Duration durationFast = Duration(milliseconds: 100);

  /// Default transition duration for most UI motion: button presses, fades,
  /// simple container transforms. Use this when unsure which duration fits.
  static const Duration durationBase = Duration(milliseconds: 200);

  /// Longer transition duration for motion that covers more of the screen,
  /// such as page transitions, dialogs, or expanding containers.
  static const Duration durationSlow = Duration(milliseconds: 400);

  /// Standard Material 3 easing. Use for simple, utilitarian motion where
  /// elements enter and exit the screen in the same way (e.g. fades, small
  /// moves) and no emphasis on the transition itself is needed.
  static const Curve curveStandard = Curves.easeInOutCubic;

  /// Emphasized easing for motion that should draw attention, such as a
  /// prominent page transition or a container transform between two
  /// meaningfully different states.
  static const Curve curveEmphasized = Curves.easeInOutCubicEmphasized;

  /// Decelerate easing for elements entering the screen: they move quickly
  /// at first and settle gently into their final position.
  static const Curve curveDecelerate = Curves.decelerate;

  /// Returns [duration], or [Duration.zero] when the user has disabled
  /// animations in their platform accessibility settings.
  ///
  /// Use for one-shot implicit animations and controller movements. Repeating
  /// controllers must instead be skipped when animations are disabled because
  /// [AnimationController.repeat] requires a nonzero period.
  static Duration resolve(BuildContext context, Duration duration) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return disableAnimations ? Duration.zero : duration;
  }
}
