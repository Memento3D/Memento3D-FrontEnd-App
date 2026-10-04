// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get modelViewerTitle => 'Mô hình 3D';

  @override
  String get modelViewerModelReady => 'Mô hình đã sẵn sàng';

  @override
  String get modelViewerReadyExplanation =>
      'Mô hình đã sẵn sàng để khám phá. Xoay mô hình để quan sát từ mọi góc độ.';

  @override
  String get modelViewerPendingExplanation =>
      'Mô hình đang được chuẩn bị. Bạn có thể khám phá khi mô hình sẵn sàng.';

  @override
  String get modelViewerUnavailableExplanation =>
      'Hiện chưa có mô hình cho mục này.';

  @override
  String modelViewerReference(String code) {
    return 'Mã tham chiếu · $code';
  }

  @override
  String get modelViewerFormat => 'Định dạng';

  @override
  String get modelViewerFormatGlb => 'GLB';

  @override
  String get modelViewerStatus => 'Trạng thái';

  @override
  String get modelViewerDetail => 'Độ chi tiết';

  @override
  String get modelViewerDetailHigh => 'Cao';

  @override
  String modelViewerPercentage(int value) {
    return '$value%';
  }

  @override
  String get modelViewerContinue => 'Tiếp tục';

  @override
  String get modelViewerPreviewName => 'Robot nhỏ · Bản xem thử';

  @override
  String get modelViewerPreviewAction =>
      'Chỉ là bản xem thử — chưa kết nối màn hình tiếp theo.';

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
  String get modelViewerPreviewTitle => 'Xem thử trình xem 3D';

  @override
  String get modelViewerInitializing => 'Đang khởi động trình xem 3D…';

  @override
  String get modelViewerReady => 'Trình xem 3D đã sẵn sàng';

  @override
  String get modelViewerShaded => 'Khối';

  @override
  String get modelViewerWireframe => 'Lưới';

  @override
  String get modelViewerGrid => 'Lưới nền';

  @override
  String get modelViewerReset => 'Đặt lại góc nhìn';

  @override
  String get modelViewerInteractionHint => 'Xoay • Thu phóng • Di chuyển';

  @override
  String get modelViewerLoading => 'Đang tải mô hình 3D…';

  @override
  String get modelViewerLoaded => 'Đã tải mô hình 3D';

  @override
  String get modelViewerLoadError => 'Không thể tải mô hình 3D.';

  @override
  String get modelViewerInitializationError =>
      'Không thể khởi động trình xem 3D. Hãy đóng màn hình này và thử lại.';

  @override
  String get modelViewerScreenTitle => 'Trình xem mô hình 3D';

  @override
  String get modelViewerFetchingOutputs => 'Đang tải thông tin mô hình…';

  @override
  String get modelViewerDownloading => 'Đang tải mô hình 3D…';

  @override
  String get modelViewerNoPrimaryGlb =>
      'Không có mô hình GLB chính cho bản scan này.';

  @override
  String get modelViewerRetry => 'Thử lại';

  @override
  String get checkPrintabilityCta => 'Kiểm tra khả năng in';

  @override
  String get rateAndShareCta => 'Đánh giá & Chia sẻ';
}
