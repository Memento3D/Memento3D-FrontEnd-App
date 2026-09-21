import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/capture_review_screen.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';

void main() {
  testWidgets('review fits Pixel 6a and missing images show a fallback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = CaptureSession()
      ..addPhoto(XFile('missing_review_image.jpg'));
    await tester.pumpWidget(
      _localizedApp(CaptureReviewScreen(session: session)),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(find.text('Phiên chụp vật thể'), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).errorBuilder, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add more returns to camera host with the same session', (
    tester,
  ) async {
    final session = CaptureSession()..addPhoto(XFile('first_missing.jpg'));
    await tester.pumpWidget(
      _localizedApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => CaptureReviewScreen(session: session),
                ),
              ),
              child: const Text('Open review'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();
    expect(find.byType(CaptureReviewScreen), findsOneWidget);
    await tester.tap(find.text('Thêm góc'));
    await tester.pumpAndSettle();
    expect(find.text('Open review'), findsOneWidget);

    session.addPhoto(XFile('second_missing.jpg'));
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();
    expect(session.photoCount, 2);
    expect(find.text('Ảnh 2'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Tiêu chuẩn'), 150);
    await tester.ensureVisible(find.text('Tiêu chuẩn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiêu chuẩn'));
    await tester.pump();
    expect(session.detailLevel, ReconstructionDetailLevel.standard);
    await tester.scrollUntilVisible(find.text('Ảnh 2'), -150);
    await tester.ensureVisible(find.text('Ảnh 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ảnh 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa khỏi phiên'));
    await tester.pumpAndSettle();
    expect(session.photoCount, 1);
    expect(find.text('Ảnh 2'), findsNothing);
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
