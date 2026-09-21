import '../l10n/app_localizations.dart';

String formatCaptureSize(AppLocalizations strings, int bytes) {
  const bytesPerKilobyte = 1024;
  const bytesPerMegabyte = bytesPerKilobyte * bytesPerKilobyte;
  if (bytes >= bytesPerMegabyte) {
    return strings.fileSizeMb((bytes / bytesPerMegabyte).toStringAsFixed(1));
  }
  return strings.fileSizeKb((bytes / bytesPerKilobyte).toStringAsFixed(1));
}
