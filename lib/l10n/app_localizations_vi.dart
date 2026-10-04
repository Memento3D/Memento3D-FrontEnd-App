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
  String get qualityRiskTitle => 'Xác nhận rủi ro';

  @override
  String get qualityNeedsConfirmation => 'CẦN XÁC NHẬN';

  @override
  String get qualityHeroTitle => 'Chất lượng ảnh chưa hoàn toàn tối ưu';

  @override
  String get qualityHeroBody =>
      'Bạn vẫn có thể dựng mô hình, nhưng một số ảnh có thể ảnh hưởng đến độ chính xác của mô hình 3D.';

  @override
  String get qualitySummaryTitle => 'Tóm tắt chất lượng ảnh';

  @override
  String get qualityQualified => 'Đạt chuẩn';

  @override
  String get qualityNeedsAttention => 'Cần lưu ý';

  @override
  String get qualityOverallScore => 'Chất lượng tổng thể';

  @override
  String qualityPercentage(String value) {
    return '$value%';
  }

  @override
  String qualityReviewImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ảnh cần được xem xét',
      zero: 'Xem cảnh báo chất lượng',
    );
    return '$_temp0';
  }

  @override
  String get qualityViewDetails => 'Xem chi tiết cảnh báo & mức độ ảnh hưởng';

  @override
  String get qualityRiskDetailsTitle => 'Kiểm tra trước khi tiếp tục';

  @override
  String qualityRiskDetailsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Xem ảnh hưởng có thể có của $count ảnh trước khi quyết định.',
      zero: 'Xem cảnh báo chất lượng trước khi quyết định.',
    );
    return '$_temp0';
  }

  @override
  String get qualityAffectedImages => 'Ảnh cần lưu ý';

  @override
  String qualityAdditionalAffectedImages(int count) {
    return 'Còn $count ảnh cần lưu ý';
  }

  @override
  String get qualityNoAffectedImages => 'Không có ảnh cần lưu ý để xem trước.';

  @override
  String get qualityImpactTitle => 'Điều này có thể ảnh hưởng gì?';

  @override
  String get qualitySurfaceRisk =>
      'Chi tiết bề mặt có thể kém sắc nét ở một số vùng.';

  @override
  String get qualityGeometryRisk =>
      'Độ chính xác hình học có thể giảm nhẹ ở những vùng chụp chưa tốt.';

  @override
  String get qualityReassurance =>
      'Bạn có thể tiếp tục với bộ ảnh hiện tại hoặc quay lại cải thiện ảnh chụp để có kết quả tốt hơn.';

  @override
  String get qualityAcknowledgement => 'Tôi hiểu rủi ro và vẫn muốn tiếp tục';

  @override
  String get qualityAcknowledgementHint =>
      'Cảnh báo chất lượng có thể ảnh hưởng đến kết quả 3D cuối cùng. Chỉ xác nhận khi bạn sẵn sàng chấp nhận những rủi ro này.';

  @override
  String get qualityCloseDetails => 'Đóng chi tiết rủi ro';

  @override
  String get qualityContextChanged =>
      'Báo cáo chất lượng đã thay đổi. Đóng bảng này và xem báo cáo hiện tại.';

  @override
  String get qualityContinue => 'Xác nhận và tiếp tục';

  @override
  String get qualitySubmitting => 'Đang xác nhận...';

  @override
  String get qualityBackToImages => 'Quay lại kiểm tra ảnh';

  @override
  String get qualityBackToReport => 'Quay lại báo cáo chất lượng';

  @override
  String get qualityBlockedStatus => 'CHƯA THỂ TIẾP TỤC';

  @override
  String get qualityRejectedTitle => 'Không thể tiếp tục với bộ ảnh này';

  @override
  String get qualityRejectedBody =>
      'Chất lượng ảnh hiện chưa phù hợp để tiếp tục. Vui lòng quay lại kiểm tra ảnh.';

  @override
  String get qualityIneligibleStatus => 'CẦN KIỂM TRA LẠI';

  @override
  String get qualityIneligibleTitle => 'Vui lòng quay lại báo cáo chất lượng';

  @override
  String get qualityIneligibleBody =>
      'Xác nhận rủi ro không khả dụng cho báo cáo này. Quay lại kiểm tra chất lượng ảnh hiện tại.';

  @override
  String get qualityRecoverableFailure =>
      'Chưa thể xác nhận yêu cầu. Lựa chọn xác nhận rủi ro của bạn đã được giữ lại; vui lòng thử lại.';

  @override
  String get qualityRetry => 'Thử xác nhận lại';

  @override
  String get qualityConfirmedStatus => 'ĐÃ XÁC NHẬN';

  @override
  String get qualityConfirmedTitle => 'Đã xác nhận rủi ro';

  @override
  String get qualityConfirmedBody => 'Xác nhận của bạn đã được chấp nhận.';
}
