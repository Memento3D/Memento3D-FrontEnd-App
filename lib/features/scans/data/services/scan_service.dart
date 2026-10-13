import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/network/api_exception.dart';
import '../models/scan_model.dart';
import '../models/scan_output_model.dart';

/// Service for managing 3D Scan Sessions with Memento3D Backend API
class ScanService {
  final ApiClient _apiClient;

  ScanService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Normalize sort field/direction for backend API
  static String? normalizeSort(String? sort) {
    if (sort == null || sort.isEmpty) return null;
    switch (sort) {
      case 'newest':
        return 'created_at:desc';
      case 'oldest':
        return 'created_at:asc';
      case 'name_asc':
        return 'name:asc';
      case 'size_desc':
        return 'total_size_bytes:desc';
      default:
        return sort;
    }
  }

  /// Normalize status query string for backend API
  static String? normalizeStatus(String? status) {
    if (status == null || status.isEmpty || status.toLowerCase() == 'all') {
      return null;
    }
    if (status.toLowerCase() == 'qualitycheck' || status.toLowerCase() == 'quality_check') {
      return 'quality_check';
    }
    return status.toLowerCase();
  }

  /// Retrieve paginated list of scans for authenticated user
  /// Optional filters: [status] ('draft', 'processing', 'done', 'failed', etc.), [page], [limit], [sort]
  Future<ScanListResponseModel> getScans({
    String? status,
    int page = 1,
    int limit = 20,
    String? sort,
  }) async {
    final queryParams = <String>[];
    queryParams.add('page=$page');
    queryParams.add('limit=$limit');

    final normalizedStatus = normalizeStatus(status);
    if (normalizedStatus != null) {
      queryParams.add('status=${Uri.encodeQueryComponent(normalizedStatus)}');
    }

    final normalizedSort = normalizeSort(sort);
    if (normalizedSort != null) {
      queryParams.add('sort=${Uri.encodeQueryComponent(normalizedSort)}');
    }

    final query = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
    final response = await _apiClient.get('${ApiConfig.scans}$query');

    if (response is Map<String, dynamic>) {
      return ScanListResponseModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      errorCode: 'ERR-017',
      message: 'Định dạng dữ liệu trả về từ máy chủ không hợp lệ.',
    );
  }

  /// Create a new 3D scan session (US-005, FR-005)
  Future<ScanModel> createScan({
    required String name,
    String? description,
    String? notes,
    String inputMode = 'image',
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ApiException(
        statusCode: 400,
        errorCode: 'ERR-017',
        message: 'Tên phiên scan không được để trống.',
      );
    }

    final requestBody = CreateScanRequestModel(
      name: trimmedName,
      description: description,
      notes: notes,
      inputMode: inputMode,
    ).toJson();

    final response = await _apiClient.post(
      ApiConfig.scans,
      body: requestBody,
    );

    if (response is Map<String, dynamic>) {
      return ScanModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      errorCode: 'ERR-017',
      message: 'Không thể giải mã dữ liệu phiên scan vừa tạo.',
    );
  }

  /// Get scan session details by ID
  Future<ScanModel> getScanById(String id) async {
    final response = await _apiClient.get('${ApiConfig.scans}/$id');

    if (response is Map<String, dynamic>) {
      return ScanModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      errorCode: 'ERR-017',
      message: 'Không thể giải mã dữ liệu chi tiết phiên scan.',
    );
  }

  /// Update editable scan session metadata (FR-024)
  Future<ScanModel> updateScan(
    String id, {
    String? name,
    String? description,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name.trim();
    if (description != null) body['description'] = description.trim();
    if (notes != null) body['notes'] = notes.trim();

    final response = await _apiClient.patch(
      '${ApiConfig.scans}/$id',
      body: body,
    );

    if (response is Map<String, dynamic>) {
      return ScanModel.fromJson(response);
    }

    throw ApiException(
      statusCode: 500,
      errorCode: 'ERR-017',
      message: 'Không thể cập nhật thông tin phiên scan.',
    );
  }

  /// Soft-delete a scan session (FR-035)
  Future<void> deleteScan(String id) async {
    await _apiClient.delete('${ApiConfig.scans}/$id');
  }

  /// Get generated output files (GLB, OBJ, ...) for a scan
  Future<ScanOutputsResponseModel> getScanOutputs(String id) async {
    final response = await _apiClient.get(ApiConfig.scanOutputs(id));
    return ScanOutputsResponseModel.fromDynamic(response);
  }
}
