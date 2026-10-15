import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../models/model_output.dart';
import '../../../reconstruction/data/real_execution_guard.dart';

/// Service for model output endpoints.
class ModelOutputService {
  final ApiClient _apiClient;

  ModelOutputService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// GET /scans/{id}/outputs
  Future<List<ModelOutput>> getModelOutputs(String scanId) async {
    final response = await _apiClient.get(ApiConfig.scanOutputs(scanId));
    final list = _extractList(response);
    if (list == null) {
      throw ApiException(
        statusCode: 500,
        errorCode: 'ERR-017',
        message: 'Unexpected model outputs payload.',
      );
    }
    final outputs = list
        .whereType<Map<String, dynamic>>()
        .map(ModelOutput.fromJson)
        .toList();
    // Outputs do not carry execution_mode. Inspect their actual owning jobs so
    // a previously generated mock artifact cannot bypass the production guard.
    for (final jobId in outputs.map((output) => output.jobId).toSet()) {
      if (jobId == null || jobId.isEmpty) {
        throw const FormatException('Model output has no owning job');
      }
      final job = await _apiClient.get(
        '/api/v1/reconstruction-jobs/${Uri.encodeComponent(jobId)}',
      );
      requireRealExecution(job);
      if (job is! Map<String, dynamic> ||
          job['job_id'] != jobId ||
          job['execution_mode'] != 'real') {
        throw const FormatException(
          'Cannot verify real model output provenance',
        );
      }
    }
    return outputs;
  }

  /// Only a GLB output is displayable in the viewer. The backend lists only
  /// available outputs and has no primary flag, so the first GLB is used
  /// when none is marked primary.
  Future<ModelOutput?> getPrimaryGlbOutput(String scanId) async {
    final outputs = await getModelOutputs(scanId);
    final glbs = outputs.where((output) => output.isGlb).toList();
    for (final output in glbs) {
      if (output.isPrimary) return output;
    }
    return glbs.isEmpty ? null : glbs.first;
  }

  List<dynamic>? _extractList(dynamic response) {
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      for (final key in const [
        'model_outputs',
        'modelOutputs',
        'outputs',
        'items',
        'data',
        'results',
      ]) {
        final value = response[key];
        if (value is List) return value;
      }
    }
    return null;
  }
}
