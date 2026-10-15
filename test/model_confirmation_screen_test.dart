import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';
import 'package:memento3d_frontend_app/screens/model_confirmation_screen.dart';
import 'package:memento3d_frontend_app/screens/processing_screen.dart';
import 'package:memento3d_frontend_app/screens/processing_state.dart';

void main() {
  testWidgets('shows overview and enables CTA when photos are present', (
    tester,
  ) async {
    final session = CaptureSession()..addPhoto(XFile('missing_confirm.jpg'));
    await tester.pumpWidget(
      _localizedApp(ModelConfirmationScreen(session: session)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tạo Mô hình 3D từ Ảnh'), findsOneWidget);
    expect(find.text('Ảnh gốc'), findsOneWidget);
    expect(find.text('Búp bê kỷ niệm'), findsOneWidget);
    // No invented consent percentage, status or time estimate.
    expect(find.text('100% Đã đồng ý'), findsNothing);

    await tester.scrollUntilVisible(find.text('Định dạng file'), 150);
    await tester.pumpAndSettle();
    expect(find.text('Ảnh đã tải lên'), findsOneWidget);
    expect(find.text('Định dạng file'), findsOneWidget);
    expect(find.text('Chuẩn 3D'), findsOneWidget);
    expect(find.text('Thời gian ước tính: 1–2 phút'), findsNothing);
    expect(find.text('Đang xử lý'), findsNothing);

    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Tạo Mô hình 3D ngay'),
    );
    expect(cta.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('amber warning shows only when there are no photos', (
    tester,
  ) async {
    await tester.pumpWidget(
      _localizedApp(ModelConfirmationScreen(session: CaptureSession())),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.textContaining('Chưa có ảnh nào sẵn sàng'),
      150,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có ảnh nào sẵn sàng'), findsOneWidget);
    final cta = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Tạo Mô hình 3D ngay'),
    );
    expect(cta.onPressed, isNull);

    final session = CaptureSession()..addPhoto(XFile('missing_confirm.jpg'));
    await tester.pumpWidget(
      _localizedApp(ModelConfirmationScreen(session: session)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Chưa có ảnh nào sẵn sàng'), findsNothing);
  });

  testWidgets('successful submit navigates to the processing screen', (
    tester,
  ) async {
    final session = CaptureSession()..addPhoto(XFile('missing_confirm.jpg'));
    await tester.pumpWidget(
      _localizedApp(
        ModelConfirmationScreen(
          session: session,
          onSubmit: (session) async => const ProcessingSnapshot.waiting(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo Mô hình 3D ngay'));
    await tester.pumpAndSettle();

    expect(find.byType(ProcessingScreen), findsOneWidget);
    final screen = tester.widget<ProcessingScreen>(
      find.byType(ProcessingScreen),
    );
    expect(screen.session, same(session));
    expect(tester.takeException(), isNull);
  });

  testWidgets('duplicate submissions are prevented while submitting', (
    tester,
  ) async {
    final session = CaptureSession()..addPhoto(XFile('missing_confirm.jpg'));
    final completer = Completer<ProcessingSnapshot>();
    var calls = 0;
    await tester.pumpWidget(
      _localizedApp(
        ModelConfirmationScreen(
          session: session,
          onSubmit: (session) {
            calls++;
            return completer.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo Mô hình 3D ngay'));
    await tester.pump();

    expect(calls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final cta = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(cta.onPressed, isNull);

    // A second tap while submitting must not trigger another request.
    await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    completer.complete(const ProcessingSnapshot.waiting());
    await tester.pumpAndSettle();
    expect(find.byType(ProcessingScreen), findsOneWidget);
  });

  testWidgets('failure keeps the user on the screen and allows retry', (
    tester,
  ) async {
    final session = CaptureSession()..addPhoto(XFile('missing_confirm.jpg'));
    var calls = 0;
    await tester.pumpWidget(
      _localizedApp(
        ModelConfirmationScreen(
          session: session,
          onSubmit: (session) async {
            calls++;
            if (calls == 1) {
              throw Exception('network down');
            }
            return const ProcessingSnapshot.waiting();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tạo Mô hình 3D ngay'));
    await tester.pumpAndSettle();

    expect(find.byType(ProcessingScreen), findsNothing);
    expect(find.byType(ModelConfirmationScreen), findsOneWidget);
    expect(
      find.text('Không thể tạo mô hình 3D. Vui lòng thử lại.'),
      findsWidgets,
    );

    await tester.tap(find.text('Tạo Mô hình 3D ngay'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(ProcessingScreen), findsOneWidget);
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
