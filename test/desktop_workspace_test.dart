import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/home/presentation/screens/desktop_workspace.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';

void main() {
  testWidgets('shows real scans, filters them and opens creation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var created = 0;
    final scan = ScanItem(
      id: '1',
      name: 'Kỷ vật',
      inputMode: ScanInputMode.image,
      status: ScanItemStatus.done,
      fileCount: 24,
      totalSizeBytes: 0,
      createdAt: DateTime.now(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: DesktopWorkspace(
          onCreate: () async {
            created++;
          },
          onDashboard: () {},
          onProfile: () {},
          onShop: () {},
          onNotifications: () {},
          loadScans: () async => [scan],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kỷ vật'), findsOneWidget);
    await tester.tap(find.text('Kỷ vật'));
    await tester.pumpAndSettle();
    expect(find.text('Mở danh sách scan'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'không có');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy bản tạo'), findsOneWidget);
    await tester.tap(find.text('Tạo scan mới'));
    await tester.pumpAndSettle();
    expect(created, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows a retry when loading scans fails', (tester) async {
    tester.view.physicalSize = const Size(1100, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: DesktopWorkspace(
          onCreate: () async {},
          onDashboard: () {},
          onProfile: () {},
          onShop: () {},
          onNotifications: () {},
          loadScans: () async => throw Exception('offline'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không thể tải danh sách scan.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
