// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get captureTitle => 'Chụp';

  @override
  String get back => 'Quay lại';

  @override
  String get moreOptions => 'Tùy chọn khác';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get moveSlowly => '✨ Di chuyển chậm quanh vật thể 🌸';

  @override
  String get keepStill =>
      'Giữ vật thể đứng yên và duy trì khoảng cách ổn định.';

  @override
  String capturedPhotos(int count) {
    return 'Đã chụp $count ảnh';
  }

  @override
  String get orbitLabel => 'Quỹ đạo 360°';

  @override
  String get distanceGood => 'Khoảng cách tốt';

  @override
  String get balanceGood => 'Cân bằng';

  @override
  String get naturalLight => 'Ánh sáng tự nhiên';

  @override
  String get grid => 'Lưới';

  @override
  String get photo => 'Ảnh';

  @override
  String get video => 'Video';

  @override
  String get preview => 'Bản xem';

  @override
  String get done => 'Xong';

  @override
  String get nextStep => 'Bước tiếp';

  @override
  String get restorationTitle => 'Phục dựng Wabi-Sabi';

  @override
  String get restorationBody =>
      'Lưu giữ từng chi tiết trong câu chuyện của vật thể.';

  @override
  String get automatic => 'Tự động';

  @override
  String get cameraUnavailable => 'Không tìm thấy camera trên thiết bị.';

  @override
  String get cameraError => 'Không thể mở camera.';

  @override
  String get captureError => 'Không thể chụp ảnh.';

  @override
  String get retry => 'Thử lại';

  @override
  String get capturePhoto => 'Chụp ảnh';

  @override
  String get photoCaptured => 'Đã chụp ảnh';

  @override
  String get wizardReadyTitle => 'Di chuyển chậm quanh vật thể';

  @override
  String get wizardReadyBody =>
      'Giữ vật thể đứng yên và duy trì khoảng cách ổn định.';

  @override
  String get wizardTiltedTitle => 'Giữ điện thoại thẳng';

  @override
  String get wizardTiltedBody =>
      'Điều chỉnh hướng điện thoại trước khi tiếp tục.';

  @override
  String get wizardMovingTitle => 'Di chuyển chậm hơn';

  @override
  String get wizardMovingBody =>
      'Chuyển động chậm giúp ghi lại hình ảnh rõ hơn.';

  @override
  String get wizardCapturedTitle => 'Đã chụp ảnh';

  @override
  String get wizardCapturedBody => 'Tiếp tục di chuyển quanh vật thể.';
}
