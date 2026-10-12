import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../dto/reconstruction_job_dto.dart';

/// Transport and wire validation only. Authentication belongs to ApiClient.
class ReconstructionApi {
  ReconstructionApi({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ReconstructionJobDto> getJob(String scanId) async {
    final response = await _apiClient.get(
      '${ApiConfig.scans}/${Uri.encodeComponent(scanId)}/job',
    );
    return ReconstructionJobDto.fromJson(response);
  }
}
