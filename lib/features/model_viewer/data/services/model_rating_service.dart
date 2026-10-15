import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';

class ModelRatingService {
  ModelRatingService({ApiClient? client}) : _client = client ?? ApiClient();
  final ApiClient _client;

  String _path(String scanId) =>
      '${ApiConfig.scans}/${Uri.encodeComponent(scanId)}/ratings';

  Future<List<Map<String, dynamic>>> getRatings(String scanId) async {
    final response = await _client.get(_path(scanId));
    if (response is! List ||
        response.any((item) => item is! Map<String, dynamic>)) {
      throw const FormatException('Invalid ratings response');
    }
    return response.cast<Map<String, dynamic>>();
  }

  Future<void> save(String scanId, int rating, String comment) async {
    if (rating < 1 || rating > 5) throw ArgumentError.value(rating, 'rating');
    final response = await _client.post(
      _path(scanId),
      body: {'rating': rating, 'comment': comment.trim()},
      expectedStatusCode: 200,
    );
    if (response is! Map<String, dynamic> || response['rating'] != rating) {
      throw const FormatException('Invalid saved rating response');
    }
  }

  Future<void> delete(String scanId) => _client.delete(_path(scanId));
}
