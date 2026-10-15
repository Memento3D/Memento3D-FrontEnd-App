import 'video_file_probe.dart';

enum VideoImportError {
  format,
  size,
  invalidSize,
  unavailable,
  picker,
  storage,
}

/// Filename suffix checks do not verify codecs, integrity or decodability.
class VideoImportPolicy {
  static const maximumBytes = 2147483648;
  static const allowedExtensions = {'mp4', 'mov', 'avi'};

  static bool allowsName(String name) {
    final basename = name.replaceAll('\\', '/').split('/').last;
    final dot = basename.lastIndexOf('.');
    return dot > 0 &&
        allowedExtensions.contains(basename.substring(dot + 1).toLowerCase());
  }

  static VideoImportError? validate(VideoFileFacts facts) {
    if (!facts.readable) return VideoImportError.unavailable;
    final bytes = facts.byteLength;
    if (bytes == null || bytes <= 0) return VideoImportError.invalidSize;
    if (bytes > maximumBytes) return VideoImportError.size;
    return null;
  }
}
