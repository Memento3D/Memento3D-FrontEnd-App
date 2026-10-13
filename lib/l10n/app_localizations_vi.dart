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

  @override
  String get uploadTitle => 'Đang tải ảnh';

  @override
  String get uploadPreparing => 'Đang chuẩn bị tải lên';

  @override
  String get uploadUploading => 'Đang tải lên';

  @override
  String get uploadWaiting => 'Đang chờ kết nối';

  @override
  String get uploadReconciling => 'Đang khôi phục';

  @override
  String get uploadRetryNeeded => 'Cần thử lại';

  @override
  String get uploadCompleted => 'Tải ảnh lên hoàn tất';

  @override
  String get uploadMainTitle => 'Đang tải bộ ảnh lên';

  @override
  String get uploadNetworkBanner => 'Đang chờ kết nối lại';

  @override
  String get uploadNetworkBody =>
      'Tiến trình đã xác nhận được giữ nguyên. Quá trình tải sẽ tiếp tục khi có kết nối trở lại.';

  @override
  String get uploadReconcilingTitle => 'Đang khôi phục phiên tải';

  @override
  String get uploadReconcilingBody =>
      'Đang kiểm tra vị trí đã xác nhận trước khi tiếp tục. Tiến trình được giữ nguyên trong lúc kiểm tra.';

  @override
  String get uploadCompletionBody => 'Đang chuyển sang kiểm tra chất lượng...';

  @override
  String get uploadFailureBody =>
      'Tiến trình đã xác nhận được giữ nguyên. Thử lại để tiếp tục từ vị trí đã xác nhận gần nhất.';

  @override
  String get uploadSourceFailureBody =>
      'Chưa thể cập nhật tiến trình tải. Tiến trình đã xác nhận được giữ nguyên; hãy thử kết nối lại.';

  @override
  String get uploadLocalPhotos => 'Ảnh trên thiết bị';

  @override
  String get uploadSavedTitle => 'Tiến trình được lưu tự động';

  @override
  String get uploadSavedBody =>
      'Bạn có thể quay lại phiên tải sau khi gián đoạn. Quá trình tải sẽ tiếp tục từ vị trí đã xác nhận gần nhất.';

  @override
  String get uploadSessionOnlyTitle => 'Giữ phiên tải này mở';

  @override
  String get uploadSessionOnlyBody =>
      'Tiến trình đã xác nhận vẫn hiển thị trong phiên này. Chưa hỗ trợ khôi phục sau khi đóng ứng dụng.';

  @override
  String uploadPhotoCount(int count) {
    return '$count ảnh';
  }

  @override
  String uploadPercent(String value) {
    return '$value%';
  }

  @override
  String uploadSummaryProgress(String value) {
    return 'Đã tải lên $value%';
  }

  @override
  String uploadUnitCount(int confirmed, int total) {
    return '$confirmed / $total';
  }

  @override
  String uploadConfirmedParts(int confirmed, int total) {
    return '$confirmed / $total phần đã tải lên';
  }

  @override
  String get uploadProgressLabel => 'Tiến trình tải đã xác nhận';

  @override
  String get uploadSpeed => 'Tốc độ';

  @override
  String uploadSpeedValue(String value) {
    return '$value MB/s';
  }

  @override
  String get uploadRemaining => 'Còn lại';

  @override
  String uploadEtaValue(int minutes, int seconds) {
    return '~$minutes phút $seconds giây';
  }

  @override
  String get uploadEtaWaiting => 'Đang chờ';

  @override
  String get uploadUnknownMetric => '—';

  @override
  String get uploadConfirmed => 'Đã tải';

  @override
  String get uploadPhotosTitle => 'Ảnh đang tải';

  @override
  String get uploadPhotoCompleted => 'Đã tải';

  @override
  String get uploadPhotoCurrent => 'Đang tải';

  @override
  String get uploadPhotoPending => 'Chờ tải';

  @override
  String get uploadPhotoPaused => 'Tạm dừng';

  @override
  String uploadPhotoDescription(String photo, String status) {
    return '$photo. $status';
  }

  @override
  String get uploadNextSteps => 'Các bước tiếp theo';

  @override
  String get uploadCloudStep => 'Tải dữ liệu lên đám mây';

  @override
  String uploadStepProgress(String status, int confirmed, int total) {
    return '$status ($confirmed/$total phần)';
  }

  @override
  String get uploadQualityStep => 'Kiểm tra chất lượng & Tiền xử lý';

  @override
  String get uploadQualityNextBody => 'Bước tiếp theo sau khi tải xong';

  @override
  String get uploadNext => 'Tiếp theo';

  @override
  String get photoUploadComplete =>
      'Tất cả ảnh đã được xác nhận tải lên. Bạn có thể quay lại màn hình chụp.';

  @override
  String get photoUploadRetrying => 'Đang thử lại ảnh chưa được gửi';

  @override
  String get photoUploadConfirm => 'Tải ảnh lên';

  @override
  String get photoUploadStopped => 'Đã dừng tải ảnh';

  @override
  String get photoUploadAmbiguous =>
      'Chưa xác nhận được kết quả tải ảnh hiện tại. Ảnh có thể đã tồn tại trên máy chủ. Đã dừng tải; ảnh này sẽ không được gửi lại.';

  @override
  String get photoUploadRejected =>
      'Máy chủ từ chối ảnh này. Đã dừng tải. Các ảnh đã xác nhận được giữ lại.';

  @override
  String get photoUploadNotSubmitted =>
      'Ảnh này chưa được gửi. Kiểm tra tệp trên thiết bị rồi chủ động thử lại.';

  @override
  String photoUploadConfirmed(int confirmed, int total) {
    return 'Đã xác nhận $confirmed / $total ảnh';
  }
}
