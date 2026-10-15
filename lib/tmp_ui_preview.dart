// TEMPORARY visual preview with mock API data; delete before committing.
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'core/theme/app_theme.dart';
import 'core/widgets/m3_ui.dart';
import 'features/home/presentation/screens/keepsakes_screen.dart';
import 'features/orders/presentation/screens/cart_screen.dart';
import 'features/orders/presentation/screens/orders_screen.dart';
import 'features/auth/presentation/screens/change_password_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/register_screen.dart';
import 'features/auth/presentation/screens/reset_password_screen.dart';
import 'features/auth/presentation/screens/verification_entry_screen.dart';
import 'features/home/presentation/screens/addresses_screen.dart';
import 'features/home/presentation/screens/main_screen.dart';
import 'features/orders/presentation/screens/checkout_screen.dart';
import 'features/orders/presentation/screens/order_detail_screen.dart';
import 'features/orders/presentation/screens/order_placed_screen.dart';
import 'features/orders/presentation/screens/payment_gateway_screen.dart';
import 'features/orders/presentation/screens/print_order_config_screen.dart';
import 'features/scans/data/models/job_model.dart';
import 'features/scans/data/services/job_service.dart';
import 'features/uploads/development/manual_upload_progress_source.dart';
import 'features/uploads/presentation/controllers/upload_progress_controller.dart';
import 'features/uploads/presentation/screens/upload_progress_screen.dart';
import 'l10n/app_localizations.dart';
import 'screens/capture_review_screen.dart';
import 'screens/capture_session.dart';
import 'screens/job_failed_screen.dart';
import 'screens/model_confirmation_screen.dart';
import 'screens/processing_screen.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

final _now = DateTime.now();
String _ago(Duration d) => _now.subtract(d).toUtc().toIso8601String();

Map<String, dynamic> _order(
  String id,
  String code,
  String status,
  String name,
  num total, {
  String? tracking,
  String payment = 'PAID',
}) => {
  'id': id,
  'orderCode': code,
  'status': status,
  'paymentMethod': 'MOMO',
  'paymentStatus': payment,
  'recipientName': 'An',
  'phone': '0123456789',
  'shippingAddress': '12 Phố A, Phường A, Hà Nội',
  'shippingCarrier': 'Giao Hàng Nhanh (GHN Express)',
  'trackingCode': ?tracking,
  'subtotal': total,
  'discountAmount': 0,
  'shippingFee': 0,
  'totalPrice': total,
  'paidAmount': payment == 'PAID' ? total : 0,
  'remainingAmount': payment == 'PAID' ? 0 : total,
  'itemCount': 1,
  'representativeProductName': name,
  'items': [
    {
      'id': 'i$id',
      'productName': name,
      'unitPrice': total,
      'quantity': 1,
      'subtotal': total,
      'material': 'Resin',
    },
  ],
};

final _orders = [
  _order('o1', 'ORD-20261029-A1B2', 'PRINTING', 'Tượng kỷ vật Đôi bạn thân',
      1600000),
  _order('o2', 'ORD-20261028-C3D4', 'SHIPPED', 'Tượng gia đình sum vầy',
      1950000, tracking: 'GHN-20261028-C3D4'),
  _order('o3', 'ORD-20261025-E5F6', 'PENDING', 'Tượng cưng cún Golden',
      750000, payment: 'PENDING'),
  _order('o4', 'ORD-20261020-G7H8', 'COMPLETED', 'Tượng kỷ vật bà Hoa',
      1200000),
];

Future<http.Response> _handler(http.Request request) async {
  final path = request.url.path;
  switch (path) {
    case '/api/v1/notifications/unread-count':
      return _json({'unreadCount': 3});
    case '/api/v1/notifications':
      return _json({
        'content': [
          {
            'id': 'n1',
            'title': 'Đơn ORD-20261029-A1B2 đang in 3D',
            'message': 'Xưởng đã bắt đầu in kỷ vật của bạn.',
            'isRead': false,
            'createdAt': _ago(const Duration(hours: 1)),
          },
        ],
        'last': true,
      });
    case '/api/v1/scans':
      return _json({
        'scans': [
          {'id': 's1', 'name': 'Tượng gốm Bát Tràng', 'status': 'done', 'input_mode': 'image', 'file_count': 186, 'total_size_bytes': 98500000, 'created_at': _ago(const Duration(hours: 2))},
          {'id': 's2', 'name': 'Bình hoa gốm men lam', 'status': 'processing', 'input_mode': 'image', 'file_count': 142, 'total_size_bytes': 74000000, 'created_at': _ago(const Duration(minutes: 30))},
          {'id': 's3', 'name': 'Tượng đôi bạn thân', 'description': 'Kỷ niệm Đà Lạt', 'status': 'done', 'input_mode': 'image', 'file_count': 48, 'total_size_bytes': 145000000, 'created_at': _ago(const Duration(days: 12))},
          {'id': 's4', 'name': 'Tượng gia đình ấm áp', 'description': 'Tổ ấm 3 thành viên', 'status': 'done', 'input_mode': 'video', 'file_count': 64, 'total_size_bytes': 88000000, 'created_at': _ago(const Duration(days: 20))},
        ],
        'total': 4,
        'page': 1,
        'limit': 50,
      });
    case '/api/v1/orders/me/counts':
      return _json({'ALL': 4, 'PRINTING': 1, 'PENDING': 1, 'SHIPPED': 1});
    case '/api/v1/orders/me':
      return _json({'orders': _orders, 'page': 1, 'total': _orders.length});
    case '/api/v1/cart':
      return _json({
        'items': [
          {'id': 'c1', 'productName': 'Tượng chân dung đôi bạn', 'categoryName': 'Resin SLA cao cấp', 'unitPrice': 1199000, 'quantity': 1, 'subtotal': 1199000, 'customization': {'engraving': 'Đế gỗ sồi khắc: "Tri kỷ 2026"'}},
          {'id': 'c2', 'productName': 'Tượng mini gia đình nhỏ', 'categoryName': 'Full-Color PolyJet', 'unitPrice': 1490000, 'quantity': 1, 'subtotal': 1490000},
          {'id': 'c3', 'productName': 'Mô hình chú cún Golden', 'categoryName': 'Resin phủ bóng', 'unitPrice': 499000, 'quantity': 1, 'subtotal': 499000},
        ],
        'subtotal': 3188000,
        'discount': 100000,
        'shippingFee': 0,
        'total': 3088000,
      });
    case '/api/v1/products':
      return _json({
        'content': [
          {'id': 'p1', 'name': 'Tượng chân dung Premium', 'shortDescription': 'Resin SLA, hoàn thiện thủ công', 'price': 1199000},
          {'id': 'p2', 'name': 'Tượng chân dung Standard', 'shortDescription': 'Resin tiêu chuẩn', 'price': 749000},
          {'id': 'p3', 'name': 'Tượng mini kỷ vật', 'shortDescription': 'PLA, 8-10cm', 'price': 499000},
        ],
      });
    case '/api/v1/customization-options':
      return _json([
        {'id': 'm1', 'optionType': 'MATERIAL', 'name': 'High-Detail Resin SLA', 'additionalPrice': 150000},
        {'id': 'm2', 'optionType': 'MATERIAL', 'name': 'PLA tiêu chuẩn', 'additionalPrice': 0},
        {'id': 'b1', 'optionType': 'BASE', 'name': 'Đế tiêu chuẩn', 'additionalPrice': 50000},
        {'id': 'b2', 'optionType': 'BASE', 'name': 'Không đế', 'additionalPrice': 0},
      ]);
    case '/api/v1/users/me/addresses':
      return _json([
        {'id': 'a1', 'recipientName': 'An', 'phone': '0123456789', 'formattedAddress': '12 Phố A, Phường A, Hà Nội', 'label': 'HOME', 'isDefault': true},
        {'id': 'a2', 'recipientName': 'An', 'phone': '0123456789', 'formattedAddress': 'Tầng 4, Tòa nhà TechHub, 88 Phố B, Phường B, Cầu Giấy, Hà Nội', 'label': 'OFFICE', 'isDefault': false},
      ]);
  }
  if (path.startsWith('/api/v1/orders/')) {
    final id = path.split('/').last;
    return _json(
      _orders.firstWhere((o) => o['id'] == id, orElse: () => _orders.first),
    );
  }
  return _json({}, 404);
}

void main() {
  http.runWithClient(() => runApp(const _PreviewApp()), () => MockClient(_handler));
}

CaptureSession _session() {
  final session = CaptureSession();
  for (var i = 0; i < 6; i++) {
    session.addPhoto(XFile('assets/images/besties_keepsake.jpg'));
  }
  return session;
}

class _DemoJobs extends JobService {
  @override
  Future<JobModel> getScanJob(String scanId) async => JobModel(
    id: 'demo-job',
    scanId: scanId,
    status: JobStatus.fromBackendValue('processing'),
    stage: jobStageFromBackendValue('shape_generation'),
    rawStage: 'shape_generation',
    progress: 0.69,
    etaSeconds: 45,
  );
}

final _screens = <(String, String, Widget Function())>[
  ('login', 'Đăng nhập', () => const LoginScreen()),
  ('register', 'Đăng ký', () => const RegisterScreen()),
  ('verify', 'Xác thực email', () => const VerificationEntryScreen(email: 'minhanh@memento3d.vn')),
  ('reset', 'Đặt lại mật khẩu', () => const ResetPasswordScreen(resetToken: 'preview-token')),
  ('change', 'Đổi mật khẩu', () => const ChangePasswordScreen()),
  ('main', 'Main (Studio · Đơn hàng · Keepsakes · Giỏ hàng)', () => const MainScreen()),
  ('orders', 'Tab Đơn hàng', () => _tab(1, const OrdersScreen(embedded: true))),
  ('keepsakes', 'Tab Keepsakes', () => _tab(2, const KeepsakesScreen())),
  ('cart', 'Tab Giỏ hàng', () => _tab(3, const CartScreen(embedded: true))),
  ('detail', 'Chi tiết đơn hàng', () => const OrderDetailScreen(orderId: 'o1')),
  ('config', 'Cấu hình đơn in 3D', () => const PrintOrderConfigScreen(scanId: 's-20261029-7', scanName: 'Chân dung bà Hoa')),
  ('checkout', 'Xác nhận đơn hàng (Checkout)', () => const CheckoutScreen()),
  ('pay', 'Thanh toán MoMo', () => PaymentGatewayScreen(
        order: _orders.first,
        payment: const {
          'paymentMethod': 'MOMO',
          'amount': 1600000,
          'qrCodeUrl': 'momo://app?action=payWithApp&orderId=ORD-20261029-A1B2',
          'deeplink': 'momo://app',
        },
      )),
  ('placed', 'Thanh toán thành công', () => OrderPlacedScreen(order: _orders.first)),
  ('addresses', 'Địa chỉ giao hàng (+ Thêm địa chỉ)', () => const AddressesScreen()),
  ('review', 'Xem lại ảnh chụp', () => CaptureReviewScreen(session: _session())),
  ('upload', 'Tiến trình tải lên', () => UploadProgressScreen(
        controller: UploadProgressController(source: ManualUploadProgressSource()),
        session: _session(),
        objectName: 'Bộ ảnh vật thể',
        onUploadCompleted: () {},
      )),
  ('confirm', 'Xác nhận mô hình', () => ModelConfirmationScreen(session: _session())),
  ('processing', 'Đang tạo mô hình 3D', () => ProcessingScreen(scanId: 'demo', jobService: _DemoJobs())),
  ('failed', 'Tác vụ thất bại', () => const JobFailedScreen(jobId: 'job-1', errorMessage: 'reconstruction_failed - insufficient features')),
];

class _PreviewApp extends StatelessWidget {
  const _PreviewApp();

  @override
  Widget build(BuildContext context) {
    final key = Uri.base.queryParameters['s'];
    final match = _screens.where((s) => s.$1 == key);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('vi'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: match.isEmpty ? const _Gallery() : match.first.$3(),
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Memento3D · Preview màn hình')),
    body: ListView(
      children: [
        for (final (_, title, build) in _screens)
          ListTile(
            title: Text(title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => build()),
            ),
          ),
      ],
    ),
  );
}

Widget _tab(int index, Widget body) => Scaffold(
  body: body,
  bottomNavigationBar: M3BottomNav(
    currentIndex: index,
    onSelect: (_) {},
    onCreate: () {},
  ),
);
