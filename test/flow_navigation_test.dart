import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/capture_wizard_storage.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/scan_wizard_screen.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/scan_details_sheet.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/processing_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildFlowApp({required Widget home}) {
  return MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    home: home,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    CaptureWizardStorage.setMockState(null);
  });

  testWidgets(
      'ScanDetailsSheet connects draft scan directly to ScanWizardScreen',
      (tester) async {
    final draftScan = ScanItem(
      id: 'scan-draft-1',
      name: 'Tượng Corgi Nháp',
      inputMode: ScanInputMode.image,
      status: ScanItemStatus.draft,
      fileCount: 0,
      totalSizeBytes: 0,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      _buildFlowApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  ScanDetailsSheet.show(
                    context,
                    scan: draftScan,
                    onRename: () {},
                    onDelete: () {},
                    onRetry: () {},
                  );
                },
                child: const Text('Open Details'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open sheet
    await tester.tap(find.text('Open Details'));
    await tester.pumpAndSettle();

    // Verify "Bắt đầu chụp quét (Guided Wizard)" button is present
    final wizardCta = find.text('Bắt đầu chụp quét (Guided Wizard)');
    expect(wizardCta, findsOneWidget);

    // Tap CTA to open wizard
    await tester.tap(wizardCta);
    await tester.pumpAndSettle();

    // Verify ScanWizardScreen is now open with correct scanId
    expect(find.byType(ScanWizardScreen), findsOneWidget);
    expect(find.text('Tượng Corgi Nháp'), findsOneWidget);
  });

  testWidgets(
      'ScanDetailsSheet connects processing scan to ProcessingScreen',
      (tester) async {
    final processingScan = ScanItem(
      id: 'scan-proc-1',
      name: 'Bình Hoa Đang Dựng',
      inputMode: ScanInputMode.video,
      status: ScanItemStatus.processing,
      fileCount: 42,
      totalSizeBytes: 12000000,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      _buildFlowApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  ScanDetailsSheet.show(
                    context,
                    scan: processingScan,
                    onRename: () {},
                    onDelete: () {},
                    onRetry: () {},
                  );
                },
                child: const Text('Open Details'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open sheet
    await tester.tap(find.text('Open Details'));
    await tester.pumpAndSettle();

    // Verify "Xem tiến trình dựng 3D (Processing)" button is present
    final procCta = find.text('Xem tiến trình dựng 3D (Processing)');
    expect(procCta, findsOneWidget);

    // Tap CTA to open ProcessingScreen
    await tester.tap(procCta);
    await tester.pumpAndSettle();

    // Verify ProcessingScreen is open
    expect(find.byType(ProcessingScreen), findsOneWidget);
  });

  testWidgets(
      'ProcessingScreen provides return to Dashboard button',
      (tester) async {
    final session = CaptureSession(scanId: 'scan-test-complete');

    await tester.pumpWidget(
      _buildFlowApp(
        home: ProcessingScreen(session: session),
      ),
    );
    await tester.pumpAndSettle();

    // Verify button exists by scrolling to it
    final returnBtn = find.text('Về danh sách phiên Scan (Dashboard)');
    await tester.scrollUntilVisible(returnBtn, 200);
    expect(returnBtn, findsOneWidget);
  });

  testWidgets(
      'End-to-End flow: ScanWizardScreen returns scanId to capture flow',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? poppedScanId;
    await tester.pumpWidget(
      _buildFlowApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                poppedScanId = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (_) => const ScanWizardScreen(
                      scanId: 'flow-scan-999',
                      scanName: 'Mô hình robot',
                    ),
                  ),
                );
              },
              child: const Text('open-wizard'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open-wizard'));
    await tester.pumpAndSettle();

    // Step through wizard to final step
    final nextBtn = find.byKey(const Key('next_step_button'));
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Start capture
    final startBtn = find.byKey(const Key('start_capture_button'));
    await tester.tap(startBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Wizard hands the scan identity back to openCreatedScanFlow
    await tester.pumpAndSettle();
    expect(poppedScanId, 'flow-scan-999');
  });
}
