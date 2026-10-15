import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../models/job_model.dart';
import '../../../reconstruction/data/real_execution_guard.dart';

/// Service for fetching scan/job progress from the backend.
class JobService {
  final ApiClient _apiClient;

  JobService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// GET /scans/{id}/job
  Future<JobModel> getScanJob(String scanId) async {
    final response = await _apiClient.get('${ApiConfig.scans}/$scanId/job');
    requireRealExecution(response);

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

  /// Resubmit the original input through the supported reconstruction API.
  /// The backend remains authoritative about whether the scan may be submitted.
  Future<JobModel> retryJob(String jobId) async {
    final original = await _apiClient.get(
      '/api/v1/reconstruction-jobs/${Uri.encodeComponent(jobId)}',
    );
    requireRealExecution(original);
    if (original is! Map<String, dynamic> ||
        original['scan_id'] is! String ||
        original['input_image_id'] is! String) {
      throw const FormatException('Invalid reconstruction job response');
    }
    final scanId = original['scan_id'] as String;
    final scan = await _apiClient.get(
      '${ApiConfig.scans}/${Uri.encodeComponent(scanId)}',
    );
    if (scan is! Map<String, dynamic>) {
      throw const FormatException('Invalid scan response');
    }
    if (scan['status'] != 'uploaded' && scan['status'] != 'ready') {
      throw ApiException(
        statusCode: 400,
        message:
            'Backend requires an uploaded or ready scan before resubmission.',
      );
    }
    final response = await _apiClient.post(
      '${ApiConfig.scans}/${Uri.encodeComponent(scanId)}/job',
      body: {
        'input_image_id': original['input_image_id'],
        'profile': original['profile'] ?? 'default',
      },
      expectedStatusCode: 202,
    );
    requireRealExecution(response);

    if (response is Map<String, dynamic>) {
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
