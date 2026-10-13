import 'dart:io';

import '../../domain/repositories/photo_upload_repository.dart';

class LocalPhotoFile implements PhotoUploadFile {
  LocalPhotoFile(this.path, {String? filename, this.mimeType})
    : filename = filename ?? path.replaceAll('\\', '/').split('/').last;
  final String path;
  @override
  final String filename;
  @override
  final String? mimeType;
  @override
  Future<int> length() => File(path).length();
  @override
  Stream<List<int>> openRead() => File(path).openRead();
}
