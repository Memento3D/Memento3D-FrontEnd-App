import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../dto/reconstruction_job_record_dto.dart';
import '../real_execution_guard.dart';

class ReconstructionJobStartApi {
  const ReconstructionJobStartApi(this.client);
  final ApiClient client;

  String _endpoint(String scanId) =>
      '${ApiConfig.scans}/${Uri.encodeComponent(scanId)}/job';

  Future<ReconstructionJobRecordDto> startJob({
    required String scanId,
    required String inputImageId,
    required String profile,
  }) async {
    final response = await client.post(
      _endpoint(scanId),
      body: {'input_image_id': inputImageId, 'profile': profile},
      expectedStatusCode: 202,
    );
    requireRealExecution(response);
    return ReconstructionJobRecordDto.fromJson(response);
  }

  Future<ReconstructionJobRecordDto> getLatestJob(String scanId) async {
    final response = await client.get(
      _endpoint(scanId),
      expectedStatusCode: 200,
    );
    requireRealExecution(response);
    return ReconstructionJobRecordDto.fromJson(response);
  }
}
