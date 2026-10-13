enum ReconstructionStartFailureKind { notSubmitted, rejected, ambiguous }

/// An ambiguous start may already have created a job. Never replay it blindly.
/// Status/error codes are metadata for future localized presentation handling.
class ReconstructionStartFailure implements Exception {
  const ReconstructionStartFailure(
    this.kind, {
    this.statusCode,
    this.errorCode,
  });
  final ReconstructionStartFailureKind kind;
  final int? statusCode;
  final String? errorCode;
}

enum ReconstructionFetchFailureKind {
  invalidInput,
  notFound,
  rejected,
  unavailable,
  invalidResponse,
}

class ReconstructionFetchFailure implements Exception {
  const ReconstructionFetchFailure(
    this.kind, {
    this.statusCode,
    this.errorCode,
  });
  final ReconstructionFetchFailureKind kind;
  final int? statusCode;
  final String? errorCode;
}
