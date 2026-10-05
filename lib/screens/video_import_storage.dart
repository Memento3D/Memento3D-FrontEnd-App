import 'dart:io';

import 'video_picker.dart';

abstract interface class VideoImportStorage {
  Future<String> promote(VideoImportCandidate candidate);
}

/// iOS's picker uses `tmp/<filename>` and overwrites collisions before Dart runs.
/// Move accepted candidates out of that namespace before any future picker.
class LocalVideoImportStorage implements VideoImportStorage {
  LocalVideoImportStorage({bool? relocate, Directory? temporaryRoot})
    : _relocate = relocate ?? Platform.isIOS,
      _temporaryRoot = temporaryRoot ?? Directory.systemTemp;
  final bool _relocate;
  final Directory _temporaryRoot;

  @override
  Future<String> promote(VideoImportCandidate candidate) async {
    if (!_relocate) return candidate.path;
    final directory = await _temporaryRoot.createTemp('memento_video_');
    // Same-filesystem rename; failure rejects import. No full-memory fallback.
    final suffix = candidate.displayName.split('.').last.toLowerCase();
    final file = await File(candidate.path)
        .rename('${directory.path}/video.$suffix');
    // No eager deletion: an old selection may still have a live player.
    // Session temporary files are left for OS cleanup, including stale results.
    return file.path;
  }
}
