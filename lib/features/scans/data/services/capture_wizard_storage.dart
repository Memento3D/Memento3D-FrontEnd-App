import 'package:shared_preferences/shared_preferences.dart';

/// Storage helper for tracking whether the user has completed or skipped
/// the Capture Preparation Wizard (Alt Flow 1a in Issue #45).
class CaptureWizardStorage {
  static const String keyCompleted = 'memento3d_has_completed_capture_wizard';

  // In-memory cache for fast sync access and unit tests
  static bool? _cachedState;

  /// Check whether the user has previously completed or skipped the capture wizard.
  static Future<bool> hasCompletedWizard() async {
    if (_cachedState != null) {
      return _cachedState!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedState = prefs.getBool(keyCompleted) ?? false;
      return _cachedState!;
    } catch (_) {
      return _cachedState ?? false;
    }
  }

  /// Mark the capture wizard as completed so future sessions can show "Skip hướng dẫn".
  static Future<void> markWizardCompleted() async {
    _cachedState = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyCompleted, true);
    } catch (_) {
      // Ignore storage errors in test or fallback environments
    }
  }

  /// Reset the wizard completion state (useful for settings or testing).
  static Future<void> resetWizardState() async {
    _cachedState = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(keyCompleted);
    } catch (_) {
      // Ignore
    }
  }

  /// Synchronously set cache for testing
  static void setMockState(bool? value) {
    _cachedState = value;
  }
}
