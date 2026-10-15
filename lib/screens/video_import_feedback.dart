import '../l10n/app_localizations.dart';
import 'video_import_policy.dart';

String videoImportMessage(AppLocalizations strings, VideoImportError error) =>
    switch (error) {
      VideoImportError.format => strings.videoImportFormatError,
      VideoImportError.size => strings.videoImportSizeError,
      VideoImportError.invalidSize => strings.videoImportValidationError,
      VideoImportError.unavailable => strings.videoUnavailable,
      VideoImportError.picker => strings.videoImportError,
      VideoImportError.storage => strings.videoImportStorageError,
    };
