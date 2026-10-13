import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/network/api_exception.dart';
import '../domain/entities/scan_image.dart';
import '../domain/models/photo_upload_failure.dart';
import '../domain/repositories/photo_upload_repository.dart';
import 'api/photo_upload_api.dart';
import 'dto/scan_image_upload_dto.dart';

class PhotoUploadRepositoryImpl implements PhotoUploadRepository {
  PhotoUploadRepositoryImpl(this.api);
  final PhotoUploadApi api;
  static const maximumBytes = 20971520;

  @override
  Future<ScanImage> uploadPhoto({
    required String scanId,
    required PhotoUploadFile photo,
  }) async {
    late http.MultipartFile file;
    try {
      if (!isBackendUuid(scanId)) throw const FormatException('Invalid scanId');
      final name = photo.filename;
      final extension = name.split('.').last.toLowerCase();
      if (!name.contains('.') || !{'jpg', 'jpeg', 'png'}.contains(extension)) {
        throw const FormatException('Unsupported photo extension');
      }
      final length = await photo.length();
      if (length <= 0 || length > maximumBytes) {
        throw const FormatException('Photo must contain 1–20971520 bytes');
      }
      // Extension supplies a request MIME label, not proof of the file contents.
      // A reliable caller-supplied MIME is validated; the backend is authoritative.
      final mime =
          photo.mimeType?.toLowerCase() ??
          (extension == 'png' ? 'image/png' : 'image/jpeg');
      if (!{'image/jpeg', 'image/jpg', 'image/png'}.contains(mime)) {
        throw const FormatException('Unsupported photo MIME');
      }
      file = http.MultipartFile(
        'file',
        photo.openRead(),
        length,
        filename: name,
        contentType: MediaType.parse(mime),
      );
    } catch (_) {
      throw const PhotoUploadFailure(
        PhotoUploadFailureKind.notSubmitted,
        'Local photo or scan identity is invalid/unavailable',
      );
    }
    try {
      final dto = await api.upload(scanId, file);
      if (dto.image.scanId.toLowerCase() != scanId.toLowerCase() ||
          dto.image.uploadStatus != 'uploaded') {
        throw const FormatException('Unconfirmed image identity/status');
      }
      return dto.image.toDomain();
    } on ApiException catch (error) {
      // 408 is also the shared client's local timeout code. 5xx and redirects
      // cannot prove rollback. No classification here authorizes automatic retry.
      final rejected =
          error.statusCode >= 400 &&
          error.statusCode < 500 &&
          error.statusCode != 408;
      throw PhotoUploadFailure(
        rejected
            ? PhotoUploadFailureKind.rejected
            : PhotoUploadFailureKind.ambiguous,
        error.message,
        statusCode: error.statusCode,
      );
    } catch (_) {
      throw const PhotoUploadFailure(
        PhotoUploadFailureKind.ambiguous,
        'Upload outcome cannot be confirmed; do not replay automatically',
      );
    }
  }
}
