import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/capture_wizard_storage.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/scan_wizard_screen.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

String? _poppedScanId;

Widget _buildTestApp({
  required String scanId,
  String? scanName,
  bool? initialHasCompletedWizard,
}) {
  return MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    // Launcher route so the wizard can pop its scanId back to the capture flow.
    home: _WizardLauncher(
      builder: (_) => ScanWizardScreen(
        scanId: scanId,
        scanName: scanName,
        initialHasCompletedWizard: initialHasCompletedWizard,
      ),
    ),
  );
}

class _WizardLauncher extends StatefulWidget {
  const _WizardLauncher({required this.builder});
  final WidgetBuilder builder;

  @override
  State<_WizardLauncher> createState() => _WizardLauncherState();
}

class _WizardLauncherState extends State<_WizardLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _poppedScanId = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: widget.builder),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CaptureWizardStorage.setMockState(null);
    _poppedScanId = null;
  });

  testWidgets('displays all 4 wizard steps and navigates Next/Back smoothly', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildTestApp(scanId: 'scan-12345678', scanName: 'Tượng Corgi'),
    );
    await tester.pumpAndSettle();

    // 1. Step 1: Chuẩn bị hậu cảnh đơn giản
    expect(find.text('Chuẩn Bị Chụp Scan 3D'), findsOneWidget);
    expect(find.text('Tượng Corgi'), findsOneWidget);
    expect(find.text('Chuẩn bị hậu cảnh đơn giản'), findsOneWidget);
    expect(find.text('BƯỚC 1 / 4 • NỀN CHỤP'), findsOneWidget);

    // Toggle before/after illustration button
    expect(find.text('❌ Nên tránh'), findsOneWidget);
    await tester.tap(find.text('❌ Nên tránh'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('before_card')), findsOneWidget);

    await tester.tap(find.text('✅ Khuyên dùng'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('after_card')), findsOneWidget);

    // Advance to Step 2
    final nextBtn = find.byKey(const Key('next_step_button'));
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // 2. Step 2: Ánh sáng đồng đều
    expect(
      find.text('Đảm bảo ánh sáng đồng đều, tránh ngược sáng'),
      findsOneWidget,
    );
    expect(find.text('BƯỚC 2 / 4 • CHIẾU SÁNG'), findsOneWidget);
    expect(
      find.text('Chiếu sáng đều 360° • Không đổ bóng đen'),
      findsOneWidget,
    );

    // Advance to Step 3
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // 3. Step 3: Cố định vật thể
    expect(
      find.text('Giữ vật thể cố định trong suốt quá trình chụp'),
      findsOneWidget,
    );
    expect(find.text('BƯỚC 3 / 4 • QUỸ ĐẠO CHỤP'), findsOneWidget);
    expect(
      find.text('Vật thể đứng yên • Bạn đi vòng tròn 360°'),
      findsOneWidget,
    );

    // Advance to Step 4
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // 4. Step 4: Duy trì khoảng cách camera hợp lý
    expect(find.text('Duy trì khoảng cách camera hợp lý'), findsOneWidget);
    expect(find.text('BƯỚC 4 / 4 • CỰ LY CAMERA'), findsOneWidget);
    expect(
      find.text('Khoảng cách chuẩn: 30 cm – 80 cm'),
      findsOneWidget,
    );

    // On step 4, the CTA is "Bắt đầu chụp"
    expect(find.byKey(const Key('start_capture_button')), findsOneWidget);
    expect(find.text('Bắt đầu chụp'), findsOneWidget);

    // Test Back button navigation
    final backBtn = find.byKey(const Key('back_step_button'));
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Should return to Step 3
    expect(
      find.text('Giữ vật thể cố định trong suốt quá trình chụp'),
      findsOneWidget,
    );
  });

  testWidgets(
      'Skip button is hidden for first-time user and shown when already completed (Alt Flow 1a)',
      (tester) async {
    // 1. First-time user: initialHasCompletedWizard = false
    await tester.pumpWidget(
      _buildTestApp(
        scanId: 'scan-first-time',
        initialHasCompletedWizard: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skip_wizard_button')), findsNothing);
    expect(find.text('Skip hướng dẫn'), findsNothing);

    // 2. Returning user who previously completed wizard: initialHasCompletedWizard = true
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      _buildTestApp(
        scanId: 'scan-returning',
        initialHasCompletedWizard: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('skip_wizard_button')), findsOneWidget);
    expect(find.text('Skip hướng dẫn'), findsOneWidget);
  });

  testWidgets(
      'Start Capture at final step marks completed and returns scanId to capture flow',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildTestApp(scanId: 'scan-alpha-123'),
    );
    await tester.pumpAndSettle();

    // Advance to Step 4
    final nextBtn = find.byKey(const Key('next_step_button'));
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Tap "Bắt đầu chụp"
    final startBtn = find.byKey(const Key('start_capture_button'));
    expect(startBtn, findsOneWidget);
    await tester.tap(startBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Wizard hands scanId back and wizard completion is persisted
    await tester.pumpAndSettle();
    expect(_poppedScanId, 'scan-alpha-123');
    final isCompleted = await CaptureWizardStorage.hasCompletedWizard();
    expect(isCompleted, isTrue);
  });

  testWidgets(
      'Skip button returns scanId to capture flow immediately',
      (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        scanId: 'scan-skip-flow',
        initialHasCompletedWizard: true,
      ),
    );
    await tester.pumpAndSettle();

    final skipBtn = find.byKey(const Key('skip_wizard_button'));
    expect(skipBtn, findsOneWidget);
    await tester.tap(skipBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.pumpAndSettle();
    expect(_poppedScanId, 'scan-skip-flow');
    final isCompleted = await CaptureWizardStorage.hasCompletedWizard();
    expect(isCompleted, isTrue);
  });

  testWidgets('renders properly in Landscape orientation without overflow', (
    tester,
  ) async {
    // Landscape physical size: 2400 x 1080
    tester.view.physicalSize = const Size(2400, 1080);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _buildTestApp(scanId: 'scan-landscape'),
    );
    await tester.pumpAndSettle();

    // Verify all contents render and no exceptions were thrown
    expect(find.text('Chuẩn bị hậu cảnh đơn giản'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('CaptureWizardStorage saves and retrieves completion status correctly',
      () async {
    SharedPreferences.setMockInitialValues({});
    CaptureWizardStorage.setMockState(null);

    expect(await CaptureWizardStorage.hasCompletedWizard(), isFalse);
    await CaptureWizardStorage.markWizardCompleted();
    expect(await CaptureWizardStorage.hasCompletedWizard(), isTrue);
    await CaptureWizardStorage.resetWizardState();
    expect(await CaptureWizardStorage.hasCompletedWizard(), isFalse);
  });
}
