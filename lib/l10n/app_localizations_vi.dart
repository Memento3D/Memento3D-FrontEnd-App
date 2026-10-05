// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get resetPasswordInvalidTitle => 'Liên kết đã hết hạn';

  @override
  String get resetPasswordInvalidBody =>
      'Không thể sử dụng liên kết đặt lại mật khẩu này. Vui lòng yêu cầu liên kết mới để tiếp tục.';

  @override
  String get resetPasswordRequestNewLink => 'Yêu cầu liên kết mới';

  @override
  String get resetPasswordBackToLogin => 'Quay lại đăng nhập';

  @override
  String get resetPasswordSuccessTitle => 'Đặt lại mật khẩu thành công';

  @override
  String get resetPasswordSuccessBody =>
      'Mật khẩu của bạn đã được đặt lại. Hãy đăng nhập bằng mật khẩu mới.';

  @override
  String get resetPasswordHeader => 'Đặt lại mật khẩu';

  @override
  String get resetPasswordTitle => 'Tạo mật khẩu mới';

  @override
  String get resetPasswordSupport => 'Tạo mật khẩu mới cho tài khoản của bạn.';

  @override
  String get resetPasswordNewPassword => 'Mật khẩu mới';

  @override
  String get resetPasswordConfirmPassword => 'Xác nhận mật khẩu';

  @override
  String get resetPasswordShowPassword => 'Hiện mật khẩu';

  @override
  String get resetPasswordHidePassword => 'Ẩn mật khẩu';

  @override
  String get resetPasswordNewRequired => 'Vui lòng nhập mật khẩu mới.';

  @override
  String get resetPasswordConfirmRequired => 'Vui lòng xác nhận mật khẩu.';

  @override
  String get resetPasswordMismatch => 'Mật khẩu xác nhận không khớp.';

  @override
  String get resetPasswordSubmit => 'Đặt lại mật khẩu';

  @override
  String get resetPasswordSubmitting => 'Đang đặt lại mật khẩu…';

  @override
  String get resetPasswordTechnicalFailure =>
      'Không thể đặt lại mật khẩu lúc này. Vui lòng thử lại.';

  @override
  String get resetPasswordRetry => 'Thử lại';

  @override
  String get resetPasswordCancel => 'Hủy';

  @override
  String get forgotPasswordSubmitting => 'Đang gửi yêu cầu…';

  @override
  String get forgotPasswordSentTitle => 'Kiểm tra email của bạn';

  @override
  String get forgotPasswordSentBody =>
      'Nếu email tồn tại, bạn sẽ nhận được hướng dẫn đặt lại mật khẩu.';

  @override
  String get forgotPasswordSentSupport =>
      'Vui lòng kiểm tra hộp thư đến và làm theo liên kết trong email để tiếp tục.';

  @override
  String get forgotPasswordGuidanceTitle => 'Chưa thấy email?';

  @override
  String get forgotPasswordSpamGuidance => 'Kiểm tra thư mục Spam / Thư rác.';

  @override
  String get forgotPasswordDeliveryGuidance =>
      'Email có thể mất vài phút để đến.';

  @override
  String get forgotPasswordResend => 'Gửi lại hướng dẫn';

  @override
  String get forgotPasswordResending => 'Đang gửi lại hướng dẫn…';

  @override
  String get forgotPasswordTechnicalFailure =>
      'Không thể gửi yêu cầu lúc này. Vui lòng thử lại.';

  @override
  String get forgotPasswordRetry => 'Thử lại';

  @override
  String get forgotPasswordHeader => 'Quên mật khẩu';

  @override
  String get forgotPasswordTitle => 'Quên mật khẩu?';

  @override
  String get forgotPasswordSubtitle =>
      'Đừng lo, chúng mình sẽ giúp bạn lấy lại quyền truy cập.';

  @override
  String get forgotPasswordEmailLabel => 'Email';

  @override
  String get forgotPasswordEmailHint => 'Nhập địa chỉ email của bạn';

  @override
  String get forgotPasswordEmailHelper =>
      'Nhập email bạn đã dùng để đăng ký tài khoản.';

  @override
  String get forgotPasswordSubmit => 'Gửi hướng dẫn đặt lại';

  @override
  String get forgotPasswordCancel => 'Hủy';

  @override
  String get forgotPasswordBackToLogin => 'Quay lại đăng nhập';

  @override
  String get forgotPasswordEmailRequired => 'Vui lòng nhập địa chỉ email.';

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

  @override
  String get reviewTitle => 'Bản xem';

  @override
  String get captureSessionTitle => 'Phiên chụp vật thể';

  @override
  String get sessionPhotoCount => 'Ảnh chụp';

  @override
  String get sessionFileSize => 'Dung lượng';

  @override
  String get sessionQuality => 'Chất lượng 3D';

  @override
  String get metricUnavailable => 'Chưa có';

  @override
  String get sizeCalculating => 'Đang tính';

  @override
  String get sizeIncomplete => 'Một số tệp không khả dụng';

  @override
  String fileSizeKb(String value) {
    return '$value KB';
  }

  @override
  String fileSizeMb(String value) {
    return '$value MB';
  }

  @override
  String get capturedPhotoSection => 'Ảnh đã chụp';

  @override
  String get addAngle => 'Thêm góc';

  @override
  String get addAngleHint => 'Chụp thêm góc nhìn';

  @override
  String photoNumber(int number) {
    return 'Ảnh $number';
  }

  @override
  String get imageUnavailable => 'Không thể mở ảnh';

  @override
  String get deletePhoto => 'Xóa khỏi phiên';

  @override
  String get retakePhoto => 'Chụp lại';

  @override
  String get closePreview => 'Đóng ảnh';

  @override
  String get detailTitle => 'Mức độ chi tiết';

  @override
  String get detailSubtitle => 'Dành cho bước dựng 3D sau này';

  @override
  String get detailStandard => 'Tiêu chuẩn';

  @override
  String get detailStandardDescription =>
      'Phù hợp để xem nhanh trên web và điện thoại.';

  @override
  String get detailHigh => 'Chi tiết cao';

  @override
  String get detailHighDescription =>
      'Giữ thêm chi tiết bề mặt cho mô hình 3D sau này.';

  @override
  String get detailSelectionOnly =>
      'Chỉ chọn tùy thích — tính năng dựng 3D chưa khả dụng.';

  @override
  String get modelPreviewUnavailable => 'Chưa có bản xem 3D';

  @override
  String get processingCta => 'Xem trạng thái xử lý';

  @override
  String get processingTitle => 'Xử lý';

  @override
  String get processingLocal => 'Phiên chụp trên thiết bị';

  @override
  String get processingCloudUnavailable => 'Chưa kết nối dịch vụ đám mây';

  @override
  String processingPhotoCount(int count) {
    return 'Đã chụp $count ảnh';
  }

  @override
  String get processingReadyTitle => 'Sẵn sàng tải lên';

  @override
  String get processingReadyBody =>
      'Ảnh đang được lưu trên thiết bị. Chức năng xử lý sẽ khả dụng khi kết nối dịch vụ.';

  @override
  String get processingWaiting => 'Đang chờ dịch vụ xử lý';

  @override
  String get processingProgressPending =>
      'Tiến độ sẽ xuất hiện khi quá trình xử lý bắt đầu.';

  @override
  String get processingStageTitle => 'Các bước xử lý';

  @override
  String get processingStagePending => 'Chưa bắt đầu';

  @override
  String get processingStageActive => 'Đang xử lý';

  @override
  String get processingStageCompleted => 'Hoàn tất';

  @override
  String get processingStageUpload => 'Tải dữ liệu lên';

  @override
  String get processingStagePrepare => 'Chuẩn bị hình ảnh';

  @override
  String get processingStageStructure => 'Dựng cấu trúc 3D';

  @override
  String get processingStageDetail => 'Tạo chi tiết';

  @override
  String get processingStageTexture => 'Tạo bề mặt và hoàn thiện';

  @override
  String get processingStageComplete => 'Hoàn thành';

  @override
  String get processingSelectedDetail => 'Mức chi tiết đã chọn';

  @override
  String get processingFileSize => 'Dung lượng trên thiết bị';

  @override
  String get processingMissingImage => 'Không thể mở ảnh đã chụp';

  @override
  String get processingNotStarted => 'Chưa tải lên hoặc bắt đầu dựng 3D.';

  @override
  String get processingUploading => 'Đang tải ảnh lên';

  @override
  String get processingRunning => 'Đang xử lý ảnh';

  @override
  String get processingCompleted => 'Đã xử lý xong';

  @override
  String get processingFailed => 'Xử lý thất bại';

  @override
  String get processingCloudConnected => 'Đã kết nối dịch vụ xử lý';

  @override
  String get processingInProgressBody =>
      'Tiến độ dựa trên cập nhật từ dịch vụ.';

  @override
  String get processingCompleteBody => 'Dịch vụ thông báo đã xử lý xong.';

  @override
  String get processingFailedBody => 'Dịch vụ xử lý đã báo lỗi.';
}
