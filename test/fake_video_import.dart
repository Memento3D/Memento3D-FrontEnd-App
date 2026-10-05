import 'dart:async';

import 'package:memento3d_frontend_app/screens/video_picker.dart';
import 'package:memento3d_frontend_app/screens/video_file_probe.dart';
import 'package:memento3d_frontend_app/screens/video_import_storage.dart';

class FakeVideoPicker implements VideoPicker {
  VideoImportCandidate? candidate;
  Completer<VideoImportCandidate?>? gate;
  bool fail = false;
  int calls = 0;
  @override
  Future<VideoImportCandidate?> pickVideo() async {
    ++calls;
    if (fail) throw StateError('picker');
    return gate == null ? candidate : await gate!.future;
  }
}

class FakeVideoFileProbe implements VideoFileProbe {
  VideoFileFacts facts = const VideoFileFacts(byteLength: 3, readable: true);
  final Map<String, VideoFileFacts> paths = {};
  Completer<VideoFileFacts>? gate;
  final List<String> calls = [];
  @override
  Future<VideoFileFacts> inspect(String path) async {
    calls.add(path);
    return gate == null ? (paths[path] ?? facts) : await gate!.future;
  }
}

class FakeVideoImportStorage implements VideoImportStorage {
  bool fail = false;
  Completer<String>? gate;
  int calls = 0;
  @override
  Future<String> promote(VideoImportCandidate candidate) async {
    ++calls;
    if (fail) throw StateError('storage');
    return gate == null ? candidate.path : await gate!.future;
  }
}
