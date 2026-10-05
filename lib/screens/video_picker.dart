/// Local candidate only; selection and validation belong to the import flow.
class VideoImportCandidate {
  const VideoImportCandidate({required this.path, required this.displayName});
  final String path;
  final String displayName;
}

abstract interface class VideoPicker {
  Future<VideoImportCandidate?> pickVideo();
}
