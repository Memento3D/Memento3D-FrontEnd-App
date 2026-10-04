import '../models/upload_progress_snapshot.dart';

/// One source/controller pair represents one upload attempt. A future adapter
/// translates confirmed backend responses into frontend snapshots here.
/// No endpoint, serialization, index base, or persistence format is assumed.
abstract interface class UploadProgressSource {
  UploadProgressSnapshot get current;
  Stream<UploadProgressSnapshot> get snapshots;

  /// Reconcile the last confirmed position before resuming. Ordinary network
  /// recovery is driven by source snapshots, not a manual Resume action.
  Future<UploadProgressSnapshot> retry();
}
