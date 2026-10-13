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
    expect(snapshot.status, ProcessingStatus.readyToUpload);
    expect(snapshot.hasMeasuredProgress, isFalse);
    expect(snapshot.progressPercent, isNull);
    expect(snapshot.uploadedBytes, isNull);
    expect(snapshot.jobId, isNull);
    for (final stage in ProcessingStage.values) {
      expect(snapshot.statusFor(stage), ProcessingStageStatus.pending);
    }
  });

  testWidgets('Review CTA requires photos and passes the same session', (
    tester,
  ) async {
    final session = CaptureSession(scanId: 'persisted-scan');
    CaptureSession? submitted;
    Future<void> upload(BuildContext context, CaptureSession value) async {
      submitted = value;
    }

    await tester.pumpWidget(
      _localizedApp(CaptureReviewScreen(session: session, onUpload: upload)),
    );
    await tester.scrollUntilVisible(find.text('Tải ảnh lên'), 150);
    await tester.ensureVisible(find.text('Tải ảnh lên'));
    await tester.pumpAndSettle();
    final disabled = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Tải ảnh lên'),
    );
    expect(disabled.onPressed, isNull);

    session.addPhoto(XFile('missing_processing_photo.jpg'));
    session.detailLevel = ReconstructionDetailLevel.standard;
    await tester.pumpWidget(
      _localizedApp(CaptureReviewScreen(session: session, onUpload: upload)),
    );
    await tester.scrollUntilVisible(find.text('Tải ảnh lên'), 150);
    await tester.ensureVisible(find.text('Tải ảnh lên'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tải ảnh lên'));
    await tester.pumpAndSettle();

    expect(submitted, same(session));
    expect(find.byType(ProcessingScreen), findsNothing);
    expect(find.text('Tiêu chuẩn'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local file size and missing image fallback are available', (
    tester,
  ) async {
    final session = CaptureSession()
      ..addPhoto(XFile.fromData(Uint8List(2048), name: 'photo.jpg'));
    await tester.pumpWidget(_localizedApp(ProcessingScreen(session: session)));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('2.0 KB'), findsOneWidget);

    final missing = CaptureSession()
      ..addPhoto(XFile('missing_processing_image.jpg'));
    await tester.pumpWidget(_localizedApp(ProcessingScreen(session: missing)));
    await tester.pumpAndSettle();
    expect(tester.widget<Image>(find.byType(Image)).errorBuilder, isNotNull);
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
