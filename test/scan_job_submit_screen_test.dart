import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_model.dart';
import 'package:memento3d_frontend_app/features/scans/data/repositories/scan_repository.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/scan_service.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/scan_job_monitor_screen.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/scan_job_submit_screen.dart';

/// Fake backend for POST /api/v1/scans/{id}/job — avoids any real HTTP call.
class _FakeScanService extends ScanService {
  _FakeScanService({this.onCreateJob});

  final Future<ReconstructionJobModel> Function(String scanId)? onCreateJob;
  int createJobCalls = 0;

  @override
  Future<ReconstructionJobModel> createReconstructionJob(String scanId) async {
    createJobCalls++;
    if (onCreateJob != null) return onCreateJob!(scanId);
    return ReconstructionJobModel(jobId: 'job-1', scanId: scanId, queuePosition: 2);
  }
}

ScanItem _scan({int fileCount = 48, int? qualityScore}) {
  return ScanItem(
    id: 'scan-1',
    name: 'Búp bê gỗ',
    inputMode: ScanInputMode.image,
    status: ScanItemStatus.ready,
    fileCount: fileCount,
    totalSizeBytes: 1024 * 1024 * 20,
    createdAt: DateTime(2026, 1, 1),
    qualityScore: qualityScore,
  );
}

ScanRepository _repositoryWith(ScanService service) {
  // ScanRepository is a singleton; point it at the fake service for this test.
  return ScanRepository.instance..setService(service);
}

Widget _app(Widget home) => MaterialApp(home: home);

void main() {
  testWidgets('shows file count, quality score and ETA overview', (tester) async {
    final repo = _repositoryWith(_FakeScanService());
    await tester.pumpWidget(
      _app(ScanJobSubmitScreen(scan: _scan(fileCount: 50, qualityScore: 92), repository: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.text('50 tệp'), findsOneWidget);
    expect(find.text('92/100'), findsOneWidget);
    expect(find.text('Tốt'), findsOneWidget);
    expect(find.textContaining('phút'), findsOneWidget);
    expect(find.text('Quay lại'), findsOneWidget);
    expect(find.text('Bắt đầu dựng 3D'), findsOneWidget);
  });

  testWidgets('amber warning shows only for warning-range scores', (tester) async {
    final repo = _repositoryWith(_FakeScanService());

    // Warning range (50-79): banner shown, submit still enabled.
    await tester.pumpWidget(
      _app(ScanJobSubmitScreen(scan: _scan(qualityScore: 65), repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('mức cảnh báo'), findsOneWidget);
    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Bắt đầu dựng 3D'),
    );
    expect(cta.onPressed, isNotNull);

    // Good score: no warning banner.
    await tester.pumpWidget(
      _app(ScanJobSubmitScreen(scan: _scan(qualityScore: 95), repository: repo)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('mức cảnh báo'), findsNothing);
  });

  testWidgets('below-minimum score blocks submit with an error banner', (tester) async {
    final repo = _repositoryWith(_FakeScanService());
    await tester.pumpWidget(
      _app(ScanJobSubmitScreen(scan: _scan(qualityScore: 30), repository: repo)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('dưới mức tối thiểu'), findsOneWidget);
    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Bắt đầu dựng 3D'),
    );
    expect(cta.onPressed, isNull);
  });

  testWidgets('back button pops the screen', (tester) async {
    final repo = _repositoryWith(_FakeScanService());
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              child: const Text('open'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ScanJobSubmitScreen(scan: _scan(qualityScore: 90), repository: repo),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanJobSubmitScreen), findsOneWidget);

    await tester.tap(find.text('Quay lại'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanJobSubmitScreen), findsNothing);
  });

  testWidgets('successful submit calls POST /scans/{id}/job and navigates to the monitor screen', (
    tester,
  ) async {
    final fakeService = _FakeScanService();
    final repo = _repositoryWith(fakeService);
    final scan = _scan(qualityScore: 90);

    await tester.pumpWidget(_app(ScanJobSubmitScreen(scan: scan, repository: repo)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bắt đầu dựng 3D'));
    await tester.pump();
    // ScanJobMonitorScreen has an indeterminate CircularProgressIndicator
    // (never settles), so advance by the route transition duration instead
    // of using pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 400));

    expect(fakeService.createJobCalls, 1);
    expect(find.byType(ScanJobMonitorScreen), findsOneWidget);
    final screen = tester.widget<ScanJobMonitorScreen>(find.byType(ScanJobMonitorScreen));
    expect(screen.scan, same(scan));
    expect(screen.job.jobId, 'job-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate taps while submitting are prevented', (tester) async {
    final completer = Completer<ReconstructionJobModel>();
    final fakeService = _FakeScanService(onCreateJob: (_) => completer.future);
    final repo = _repositoryWith(fakeService);

    await tester.pumpWidget(
      _app(ScanJobSubmitScreen(scan: _scan(qualityScore: 90), repository: repo)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bắt đầu dựng 3D'));
    await tester.pump();

    expect(fakeService.createJobCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(ElevatedButton).last, warnIfMissed: false);
    await tester.pump();
    expect(fakeService.createJobCalls, 1);

    completer.complete(const ReconstructionJobModel(jobId: 'job-2', scanId: 'scan-1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ScanJobMonitorScreen), findsOneWidget);
  });

  testWidgets('failed submit keeps the user on screen and shows the error', (tester) async {
    var calls = 0;
    final fakeService = _FakeScanService(
      onCreateJob: (scanId) async {
        calls++;
        if (calls == 1) {
          throw ApiException(statusCode: 500, message: 'Máy chủ đang bận, vui lòng thử lại.');
        }
        return ReconstructionJobModel(jobId: 'job-3', scanId: scanId);
      },
    );
    final repo = _repositoryWith(fakeService);

    await tester.pumpWidget(
      _app(ScanJobSubmitScreen(scan: _scan(qualityScore: 90), repository: repo)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bắt đầu dựng 3D'));
    await tester.pumpAndSettle();

    expect(find.byType(ScanJobMonitorScreen), findsNothing);
    expect(find.text('Máy chủ đang bận, vui lòng thử lại.'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu dựng 3D'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(calls, 2);
    expect(find.byType(ScanJobMonitorScreen), findsOneWidget);
  });
}
