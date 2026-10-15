import 'package:http/http.dart' as http;

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_config.dart';
import '../dto/scan_image_upload_dto.dart';

class PhotoUploadApi {
  PhotoUploadApi(this.client);
  final ApiClient client;
  Future<ScanImageUploadDto> upload(
    String scanId,
    http.MultipartFile file,
  ) async {
    final body = await client.postMultipart(
      '${ApiConfig.scans}/${Uri.encodeComponent(scanId)}/images',
      files: [file],
      expectedStatusCode: 201,
    );
    return ScanImageUploadDto.fromJson(body);
  }
}
