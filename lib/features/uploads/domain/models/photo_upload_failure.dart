enum PhotoUploadFailureKind { notSubmitted, rejected, ambiguous }

/// An HTTP response is not always evidence of rollback (notably 5xx/408).
class PhotoUploadFailure implements Exception {
  const PhotoUploadFailure(this.kind, this.message, {this.statusCode});
  final PhotoUploadFailureKind kind;
  final String message;
  final int? statusCode;
  @override
  String toString() => 'PhotoUploadFailure($kind, $message)';
}
