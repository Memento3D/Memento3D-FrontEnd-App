/// ErrorMapper as specified in FRONTEND_ARCHITECTURE.md (utils/errorMapper.ts)
/// Maps error codes ERR-001 to ERR-017 and backend messages to user-friendly Vietnamese text.
class ErrorMapper {
  /// Standard error messages defined in Architecture Blueprint
  static const Map<String, String> errorMessages = {
    'ERR-001': 'Email đã được sử dụng.',
    'ERR-002': 'Email hoặc mật khẩu không đúng.',
    'ERR-003': 'Định dạng file không được hỗ trợ. Chấp nhận: JPG, PNG, MP4, MOV, AVI.',
    'ERR-004': 'File vượt giới hạn cho phép (20 MB cho ảnh, 2 GB cho video).',
    'ERR-005': 'Ảnh cần ít nhất độ phân giải 1280×720 pixel.',
    'ERR-006': 'Video cần độ dài ít nhất 10 giây.',
    'ERR-007': 'Cần ít nhất 10 ảnh đạt chất lượng sau kiểm tra để dựng mô hình.',
    'ERR-008': 'Quá trình kiểm tra chất lượng gặp sự cố. Vui lòng thử lại.',
    'ERR-009': 'Quá trình xử lý 3D vượt quá thời gian cho phép.',
    'ERR-010': 'Hệ thống đang quá tải tài nguyên ổ đĩa (< 10 GB). Vui lòng thử lại sau.',
    'ERR-011': 'Dung lượng lưu trữ đã hết (10 GB). Vui lòng xóa bớt scan cũ để tiếp tục.',
    'ERR-012': 'Quá nhiều yêu cầu. Vui lòng thử lại sau.',
    'ERR-013': 'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. Vui lòng đăng nhập lại.',
    'ERR-014': 'Định dạng MIME của file không hợp lệ.',
    'ERR-015': 'File độc hại hoặc không an toàn. Không thể xử lý.',
    'ERR-016': 'Phiên dựng 3D cho đối tượng này đã tồn tại.',
    'ERR-017': 'Đã xảy ra lỗi hệ thống. Vui lòng liên hệ hỗ trợ.',
  };

  /// Resolves the corresponding ERR-xxx code given HTTP status and raw message
  static String resolveErrorCode({
    String? backendErrorCode,
    int? statusCode,
    String? rawMessage,
  }) {
    if (backendErrorCode != null && errorMessages.containsKey(backendErrorCode.toUpperCase())) {
      return backendErrorCode.toUpperCase();
    }

    final msg = rawMessage?.toLowerCase() ?? '';

    switch (statusCode) {
      case 409:
        if (msg.contains('email') || msg.contains('already')) {
          return 'ERR-001';
        }
        return 'ERR-017';

      case 401:
        if (msg.contains('bad credentials') ||
            msg.contains('invalid credentials') ||
            msg.contains('password') ||
            msg.contains('không đúng') ||
            msg.contains('login failed')) {
          return 'ERR-002';
        }
        return 'ERR-013';

      case 403:
        if (msg.contains('quota') || msg.contains('storage') || msg.contains('dung lượng')) {
          return 'ERR-011';
        }
        return 'ERR-017';

      case 413:
        return 'ERR-004';

      case 429:
        return 'ERR-012';

      case 503:
        return 'ERR-010';

      case 504:
        return 'ERR-009';

      case 400:
        if (msg.contains('format') || msg.contains('extension')) {
          return 'ERR-003';
        }
        if (msg.contains('resolution') || msg.contains('1280')) {
          return 'ERR-005';
        }
        if (msg.contains('video') || msg.contains('10s') || msg.contains('10 giây')) {
          return 'ERR-006';
        }
        if (msg.contains('quality') || msg.contains('10 ảnh')) {
          return 'ERR-007';
        }
        if (msg.contains('mime')) {
          return 'ERR-014';
        }
        if (msg.contains('virus') || msg.contains('malicious') || msg.contains('độc hại')) {
          return 'ERR-015';
        }
        return 'ERR-017';

      case 500:
      default:
        return 'ERR-017';
    }
  }

  /// Maps an error code or status code to a human-readable Vietnamese message
  static String map({
    String? errorCode,
    int? statusCode,
    String? rawMessage,
    Map<String, String>? validationErrors,
  }) {
    // If field-level validation errors exist, prioritize the first validation message
    if (validationErrors != null && validationErrors.isNotEmpty) {
      return validationErrors.values.first;
    }

    final resolvedCode = resolveErrorCode(
      backendErrorCode: errorCode,
      statusCode: statusCode,
      rawMessage: rawMessage,
    );

    return errorMessages[resolvedCode] ?? 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
  }

  /// Maps a raw backend job error message to a friendly Vietnamese text.
  static String friendlyJobErrorMessage(String? rawMessage) {
    if (rawMessage == null || rawMessage.trim().isEmpty) {
      return 'Đã xảy ra lỗi khi tạo mô hình 3D. Vui lòng thử lại.';
    }
    final lower = rawMessage.toLowerCase();
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Quá trình xử lý mất quá nhiều thời gian. Vui lòng thử lại.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng.';
    }
    if (lower.contains('insufficient') || lower.contains('not enough')) {
      return 'Cần thêm ảnh để tái tạo mô hình. Vui lòng chụp thêm ảnh.';
    }
    if (lower.contains('image')) {
      return 'Không thể xử lý ảnh đã chụp. Vui lòng chụp lại và thử lại.';
    }
    if (lower.contains('reconstruct') || lower.contains('sfm') || lower.contains('mvs')) {
      return 'Không thể dựng lại cấu trúc 3D từ ảnh. Vui lòng thử lại.';
    }
    if (lower.contains('internal') || lower.contains('server')) {
      return 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.';
    }
    return rawMessage;
  }
}
