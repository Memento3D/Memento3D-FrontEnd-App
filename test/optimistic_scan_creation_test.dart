import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/core/utils/app_messenger.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_model.dart';
import 'package:memento3d_frontend_app/features/scans/data/repositories/scan_repository.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/scan_service.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/scan_sync_manager.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/controllers/scan_state.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/scan_wizard_screen.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/create_scan_bottom_sheet.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';

/// Mock ScanService that allows configurable network delays and responses
class MockDelayScanService extends ScanService {
  final Completer<ScanModel> completer = Completer<ScanModel>();
  bool failWithQuota = false;
  bool failWithNetwork = false;
  int callCount = 0;

  MockDelayScanService({ApiClient? apiClient}) : super(apiClient: apiClient);

  @override
  Future<ScanModel> createScan({
    required String name,
    String? description,
    String? notes,
    String inputMode = 'image',
  }) async {
    callCount++;
    if (failWithQuota) {
      throw ApiException(
        statusCode: 403,
        errorCode: 'ERR-011',
        message: 'Dung lượng lưu trữ đã hết (10 GB). Vui lòng xóa bớt scan cũ để tiếp tục.',
      );
    }
    if (failWithNetwork) {
      throw ApiException(
        statusCode: 500,
        errorCode: 'ERR-017',
        message: 'Lỗi kết nối máy chủ.',
      );
    }

    return completer.future;
  }
}

Widget _buildTestApp({required Widget home}) {
  return MaterialApp(
    navigatorKey: AppMessenger.navigatorKey,
    scaffoldMessengerKey: AppMessenger.messengerKey,
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
    GoogleFonts.config.allowRuntimeFetching = false;
    ScanSyncManager.instance.clear();
  });

  group('Optimistic Scan Creation - ScanState & ScanRepository', () {
    test('ScanState.createScanOptimistic adds scan to list immediately without waiting', () {
      final mockService = MockDelayScanService();
      final scanState = ScanState(scanService: mockService);

      expect(scanState.scans.isEmpty, true);

      // Trigger optimistic creation
      final optimisticScan = scanState.createScanOptimistic(
        name: 'Tượng Corgi Nháp',
        description: 'Mô tả test',
      );

      // 1. Returns immediately
      expect(optimisticScan.name, 'Tượng Corgi Nháp');
      expect(optimisticScan.id.startsWith('temp_'), true);
      expect(optimisticScan.status, 'draft');

      // 2. Already present in scans list
      expect(scanState.scans.length, 1);
      expect(scanState.scans.first.name, 'Tượng Corgi Nháp');
      expect(scanState.totalCount, 1);

      // 3. Sync status is in flight (syncing)
      expect(ScanSyncManager.instance.getStatus(optimisticScan.id), ScanSyncState.syncing);
    });

    test('ScanState updates scan with permanent server ID upon successful DB sync', () async {
      final mockService = MockDelayScanService();
      final scanState = ScanState(scanService: mockService);

      final optimisticScan = scanState.createScanOptimistic(name: 'Bình hoa gốm');
      expect(scanState.scans.first.id, optimisticScan.id);

      // Complete server future with permanent ID
      final serverScan = ScanModel(
        id: 'scan-server-real-123',
        name: 'Bình hoa gốm',
        status: 'draft',
        createdAt: DateTime.now(),
      );
      mockService.completer.complete(serverScan);

      await Future.delayed(const Duration(milliseconds: 50));

      // Reconciled in state list
      expect(scanState.scans.first.id, 'scan-server-real-123');
      expect(ScanSyncManager.instance.resolveId(optimisticScan.id), 'scan-server-real-123');
      expect(ScanSyncManager.instance.getStatus(optimisticScan.id), ScanSyncState.synced);
    });

    test('ScanState rolls back optimistic scan from list when DB sync fails', () async {
      final mockService = MockDelayScanService()..failWithNetwork = true;
      final scanState = ScanState(scanService: mockService);

      final optimisticScan = scanState.createScanOptimistic(name: 'Scan bị lỗi');
      expect(scanState.scans.length, 1);

      await Future.delayed(const Duration(milliseconds: 50));

      // Rolled back from list
      expect(scanState.scans.isEmpty, true);
      expect(scanState.totalCount, 0);
      expect(ScanSyncManager.instance.getStatus(optimisticScan.id), ScanSyncState.failed);
      expect(scanState.errorMessage, contains('Lỗi kết nối máy chủ'));
    });

    test('ScanRepository.createScanOptimistic creates immediately and reconciles on success', () async {
      final mockService = MockDelayScanService();
      final repository = ScanRepository.instance;
      repository.setService(mockService);

      final optimisticScan = repository.createScanOptimistic(
        name: 'Đôi Giày Sneaker',
        inputMode: ScanInputMode.image,
      );

      expect(optimisticScan.id.startsWith('temp_'), true);
      expect(repository.scans.any((s) => s.id == optimisticScan.id), true);

      // Server completes
      mockService.completer.complete(
        ScanModel(
          id: 'server-sneaker-888',
          name: 'Đôi Giày Sneaker',
          status: 'draft',
          createdAt: DateTime.now(),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(ScanSyncManager.instance.resolveId(optimisticScan.id), 'server-sneaker-888');
      expect(repository.scans.any((s) => s.id == 'server-sneaker-888'), true);
    });
  });

  group('CreateScanBottomSheet UI Optimistic Interaction', () {
    testWidgets('Submitting CreateScanBottomSheet closes immediately and navigates to ScanWizardScreen',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockService = MockDelayScanService();
      final scanState = ScanState(scanService: mockService);

      await tester.pumpWidget(
        _buildTestApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => CreateScanBottomSheet.show(ctx, scanState: scanState),
                  child: const Text('Mở Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open bottom sheet
      await tester.tap(find.text('Mở Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateScanBottomSheet), findsOneWidget);

      // Fill in scan name
      await tester.enterText(find.byType(TextFormField).first, 'Mô hình robot 3D');
      await tester.pump();

      // Tap submit button: "Bắt đầu Quét Ngay"
      await tester.tap(find.text('Bắt đầu Quét Ngay'));
      await tester.pump(); // Start transition

      // Modal bottom sheet should be dismissed immediately without waiting for server future
      await tester.pumpAndSettle();

      expect(find.byType(CreateScanBottomSheet), findsNothing);
      expect(find.byType(ScanWizardScreen), findsOneWidget);

      // State already has the scan
      expect(scanState.scans.any((s) => s.name == 'Mô hình robot 3D'), true);
    });
  });
}
