import '../../../../core/network/api_exception.dart';
import '../../domain/entities/reconstruction_job.dart';
import '../../domain/models/reconstruction_failure.dart';
import '../../domain/repositories/reconstruction_repository.dart';
import '../api/reconstruction_api.dart';
import '../dto/reconstruction_job_dto.dart';

class ReconstructionRepositoryImpl implements ReconstructionRepository {
  const ReconstructionRepositoryImpl(this.api);
  final ReconstructionApi api;

  bool _isRejection(int status) =>
      status >= 400 && status < 500 && status != 408;
  bool _sameId(String a, String b) => a.toLowerCase() == b.toLowerCase();

  @override
  Future<ReconstructionJob> startJob({
    required String scanId,
    required String inputImageId,
    String profile = defaultReconstructionProfile,
  }) async {
    if (!isReconstructionUuid(scanId) ||
        !isReconstructionUuid(inputImageId) ||
        profile != defaultReconstructionProfile) {
      throw const ReconstructionStartFailure(
        ReconstructionStartFailureKind.notSubmitted,
      );
    }
    try {
      final job = (await api.startJob(
        scanId: scanId,
        inputImageId: inputImageId,
        profile: profile,
      )).toDomain();
      if (!_sameId(job.scanId, scanId) ||
          !_sameId(job.inputImageId, inputImageId) ||
          job.profile != profile) {
        throw const FormatException('Unexpected reconstruction job identity');
      }
      return job;
    } on ApiException catch (error) {
      throw ReconstructionStartFailure(
        _isRejection(error.statusCode)
            ? ReconstructionStartFailureKind.rejected
            : ReconstructionStartFailureKind.ambiguous,
        statusCode: error.statusCode,
        errorCode: error.errorCode,
      );
    } catch (_) {
      throw const ReconstructionStartFailure(
        ReconstructionStartFailureKind.ambiguous,
      );
    }
  }

  @override
  Future<ReconstructionJob> getLatestJob({required String scanId}) async {
    if (!isReconstructionUuid(scanId)) {
      throw const ReconstructionFetchFailure(
        ReconstructionFetchFailureKind.invalidInput,
      );
    }
    try {
      final job = (await api.getLatestJob(scanId)).toDomain();
      if (!_sameId(job.scanId, scanId)) {
        throw const FormatException('Unexpected scan identity');
      }
      return job;
    } on ApiException catch (error) {
      throw ReconstructionFetchFailure(
        error.statusCode == 404
            ? ReconstructionFetchFailureKind.notFound
            : _isRejection(error.statusCode)
            ? ReconstructionFetchFailureKind.rejected
            : error.statusCode >= 200 && error.statusCode < 300
            ? ReconstructionFetchFailureKind.invalidResponse
            : ReconstructionFetchFailureKind.unavailable,
        statusCode: error.statusCode,
        errorCode: error.errorCode,
      );
    } on FormatException {
      throw const ReconstructionFetchFailure(
        ReconstructionFetchFailureKind.invalidResponse,
      );
    } catch (_) {
      throw const ReconstructionFetchFailure(
        ReconstructionFetchFailureKind.unavailable,
      );
    }
  }
}
