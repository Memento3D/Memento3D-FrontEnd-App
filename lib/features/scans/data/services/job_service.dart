import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../models/job_model.dart';

/// Service for fetching scan/job progress from the backend.
class JobService {
  final ApiClient _apiClient;

  JobService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /scans/{id}/job
  Future<JobModel> getScanJob(String scanId) async {
    final response = await _apiClient.get('${ApiConfig.scans}/$scanId/job');

    if (response is Map<String, dynamic>) {
      // The backend may wrap the job payload, e.g. { "job": {...} }
      final jobJson = response['job'] is Map<String, dynamic>
          ? response['job'] as Map<String, dynamic>
          : response;
      return JobModel.fromJson(jobJson);
    }

    throw ApiException(
      statusCode: 500,
      errorCode: 'ERR-017',
      message: 'Định dạng dữ liệu tiến trình không hợp lệ.',
    );
  }
}
