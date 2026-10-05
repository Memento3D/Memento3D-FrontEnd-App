import 'dart:io';

class VideoFileFacts {
  const VideoFileFacts({this.byteLength, this.readable = false});
  final int? byteLength;
  final bool readable;
}

abstract interface class VideoFileProbe {
  Future<VideoFileFacts> inspect(String path);
}

class LocalVideoFileProbe implements VideoFileProbe {
  @override
  Future<VideoFileFacts> inspect(String path) async {
    if (path.trim().isEmpty) return const VideoFileFacts();
    try {
      final file = File(path);
      final stat = await file.stat();
      if (stat.type != FileSystemEntityType.file) return const VideoFileFacts();
      final length = await file.length();
      final handle = await file.open(mode: FileMode.read);
      try {
        final bytes = await handle.read(1);
        return VideoFileFacts(byteLength: length, readable: bytes.isNotEmpty);
      } finally {
        await handle.close();
      }
    } catch (_) {
      return const VideoFileFacts();
    }
  }
}
