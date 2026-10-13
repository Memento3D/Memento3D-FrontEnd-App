import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../dto/reconstruction_job_dto.dart';

class ReconstructionApi {
  const ReconstructionApi(this.client);
  final ApiClient client;

  String _endpoint(String scanId) =>
      '${ApiConfig.scans}/${Uri.encodeComponent(scanId)}/job';

  Future<ReconstructionJobDto> startJob({
    required String scanId,
    required String inputImageId,
    required String profile,
  }) async => ReconstructionJobDto.fromJson(
    await client.post(
      _endpoint(scanId),
      body: {'input_image_id': inputImageId, 'profile': profile},
      expectedStatusCode: 202,
    ),
  );

  Future<ReconstructionJobDto> getLatestJob(String scanId) async =>
      ReconstructionJobDto.fromJson(
        await client.get(_endpoint(scanId), expectedStatusCode: 200),
      );
}
