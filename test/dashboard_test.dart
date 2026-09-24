import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/repositories/scan_repository.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/dashboard_screen.dart';

void main() {
  group('ScanRepository Tests', () {
    final repo = ScanRepository.instance;

    test('Initial scans list is empty when no mock data is loaded', () {
      final scans = repo.getScans();
      expect(scans.isEmpty, true);
    });

    test('Create, rename and delete scan lifecycle works dynamically', () {
      final created = repo.createScan(
        name: 'Tượng Gốm Bát Tràng',
        inputMode: ScanInputMode.image,
        description: 'Đồ gốm thủ công mỹ nghệ',
      );
      expect(created.name, 'Tượng Gốm Bát Tràng');
      expect(created.status, ScanItemStatus.draft);
      expect(repo.getScans().length, 1);

      // Search
      final searchResult = repo.getScans(searchQuery: 'Bát Tràng');
      expect(searchResult.length, 1);

      // Rename
      final renamed = repo.updateScanName(created.id, 'Tượng Gốm Bát Tràng Cổ');
      expect(renamed?.name, 'Tượng Gốm Bát Tràng Cổ');
      expect(repo.getScans().first.name, 'Tượng Gốm Bát Tràng Cổ');

      // Delete
      final deleted = repo.deleteScan(created.id);
      expect(deleted, true);
      expect(repo.getScans().isEmpty, true);
    });
  });

  group('DashboardScreen Widget Tests', () {
    testWidgets('Renders Dashboard with user name, empty state when no scans, and no quota card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(userName: 'Đăng'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify personalized greeting
      expect(find.text('Xin chào, Đăng! 👋'), findsOneWidget);
      expect(find.text('Đ'), findsOneWidget); // Avatar letter

      // 2. Verify StorageQuotaCard ("Dung lượng Cloud 3D") is REMOVED
      expect(find.text('Dung lượng Cloud 3D'), findsNothing);
      expect(find.text('Nâng cấp gói >'), findsNothing);

      // 3. Verify Empty State is shown when no scans
      expect(find.text('Chưa có phiên scan nào'), findsOneWidget);

      // 4. Verify Stats and Search
      expect(find.text('Tổng Scans'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // 5. Verify Floating Action Button
      expect(find.text('Tạo Scan Mới'), findsWidgets);
    });

    testWidgets('Extracts custom user name correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(userName: 'dangp2660'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Xin chào, dangp2660! 👋'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });
  });
}
