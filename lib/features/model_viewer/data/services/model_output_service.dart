import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../models/model_output.dart';

/// Service for model output endpoints.
class ModelOutputService {
  final ApiClient _apiClient;

  ModelOutputService({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  /// GET /scans/{id}/model-outputs
  Future<List<ModelOutput>> getModelOutputs(String scanId) async {
    final response = await _apiClient.get(
      '${ApiConfig.scans}/$scanId/model-outputs',
    );
    final list = _extractList(response);
    if (list == null) {
      throw ApiException(
        statusCode: 500,
        errorCode: 'ERR-017',
        message: 'Unexpected model outputs payload.',
      );
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(ModelOutput.fromJson)
        .toList();
  }

  /// Only the primary GLB output is displayable in the viewer.
  Future<ModelOutput?> getPrimaryGlbOutput(String scanId) async {
    final outputs = await getModelOutputs(scanId);
    for (final output in outputs) {
      if (output.isGlb && output.isPrimary) return output;
    }
    return null;
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
