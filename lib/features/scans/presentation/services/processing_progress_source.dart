import '../models/processing_state.dart';

/// Local lifecycle token, not a backend job/event identifier.
class ProcessingUpdate {
  const ProcessingUpdate(this.attempt, this.snapshot);
  final int attempt;
  final ProcessingSnapshot snapshot;
}

/// A controller exclusively owns and disposes its source. Retry switches to the
/// supplied attempt and publishes/updates current before completing. Adapters
/// supply presentation-safe errors, never raw transport exceptions.
abstract interface class ProcessingProgressSource {
  ProcessingUpdate get current;
  Stream<ProcessingUpdate> get updates;
  Future<void> retry(int attempt);
  void dispose();
}
