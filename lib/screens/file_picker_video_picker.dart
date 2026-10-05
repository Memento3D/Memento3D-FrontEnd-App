import 'package:file_picker/file_picker.dart';

import 'video_picker.dart';

/// The only application adapter that knows the native picker package.
class FilePickerVideoPicker implements VideoPicker {
  @override
  Future<VideoImportCandidate?> pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mov', 'avi'],
      allowMultiple: false,
      withData: false,
      withReadStream: false,
      compressionQuality: 0,
    );
    if (result == null) return null;
    final file = result.files.single;
    return VideoImportCandidate(path: file.path ?? '', displayName: file.name);
  }
}
