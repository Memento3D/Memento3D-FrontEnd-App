import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/capture_review_screen.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/processing_screen.dart';
import 'package:memento3d_frontend_app/screens/processing_state.dart';

void main() {
  test('initial processing state contains no invented progress', () {
    const snapshot = ProcessingSnapshot.waiting();
    expect(snapshot.status, ProcessingStatus.waiting);
    expect(snapshot.hasMeasuredProgress, isFalse);
    expect(snapshot.progress, isNull);
    expect(snapshot.etaSeconds, isNull);
    expect(snapshot.stage, isNull);
    for (final stage in JobStage.values) {
      expect(snapshot.statusFor(stage), ProcessingStageStatus.pending);
    }
  });

  test('stage order matches the real backend pipeline', () {
    expect(JobStage.values.map((s) => s.name).toList(), const [
      'queued',
      'downloading',
      'preprocessing',
      'shapeGeneration',
      'texturing',
      'validating',
      'exporting',
      'uploading',
      'done',
    ]);
  });

  testWidgets('Review CTA requires photos and passes the same session', (
    tester,
  ) async {
    final session = CaptureSession();
    await tester.pumpWidget(
      _localizedApp(CaptureReviewScreen(session: session)),
    );
    await tester.scrollUntilVisible(find.text('Xem trạng thái xử lý'), 150);
    await tester.ensureVisible(find.text('Xem trạng thái xử lý'));
    await tester.pumpAndSettle();
    final disabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Xem trạng thái xử lý'),
    );
    expect(disabled.onPressed, isNull);

    session.addPhoto(XFile('missing_processing_photo.jpg'));
    session.detailLevel = ReconstructionDetailLevel.standard;
    await tester.pumpWidget(
      _localizedApp(CaptureReviewScreen(session: session)),
    );
    await tester.scrollUntilVisible(find.text('Xem trạng thái xử lý'), 150);
    await tester.ensureVisible(find.text('Xem trạng thái xử lý'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xem trạng thái xử lý'));
    await tester.pumpAndSettle();

    final screen = tester.widget<ProcessingScreen>(
      find.byType(ProcessingScreen),
    );
    expect(screen.session, same(session));
    expect(find.text('Đang tạo mô hình 3D...'), findsOneWidget);
    expect(find.text('Chưa bắt đầu'), findsOneWidget);
    expect(find.text('--%'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing image fallback is available', (tester) async {
    final missing = CaptureSession()
      ..addPhoto(XFile('missing_processing_image.jpg'));
    await tester.pumpWidget(_localizedApp(ProcessingScreen(session: missing)));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Image>(find.byType(Image)).errorBuilder, isNotNull);
    expect(tester.takeException(), isNull);

    final session = CaptureSession()
      ..addPhoto(XFile.fromData(Uint8List(2048), name: 'photo.jpg'));
    await tester.pumpWidget(_localizedApp(ProcessingScreen(session: session)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Widget _localizedApp(Widget home) => MaterialApp(
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
