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
import 'package:memento3d_frontend_app/features/reconstruction/presentation/controllers/processing_controller.dart';

import '../helpers/mock_processing_progress_source.dart';

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
    expect(find.text('Đã chụp 1 ảnh'), findsOneWidget);
    expect(find.text('Sẵn sàng tải lên'), findsOneWidget);
    expect(
      find.text(
        AppLocalizations.of(tester.element(find.byType(ProcessingScreen)))!
            .processingProvenanceUnknown,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('%'), findsNothing);
    await tester.scrollUntilVisible(find.text('Tiêu chuẩn'), 150);
    expect(find.text('Tiêu chuẩn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('local file size and missing image fallback are available', (
    tester,
  ) async {
    final session = _MemorySession()
      ..addPhoto(XFile.fromData(Uint8List(2048), name: 'photo.jpg'));
    await tester.pumpWidget(_localizedApp(ProcessingScreen(session: session)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('2.0 KB'), 150);
    expect(find.text('2.0 KB'), findsOneWidget);

    final missing = CaptureSession()
      ..addPhoto(XFile('missing_processing_image.jpg'));
    await tester.pumpWidget(_localizedApp(ProcessingScreen(session: missing)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(Image), -150);
    expect(tester.widget<Image>(find.byType(Image)).errorBuilder, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('injected progression renders stages and terminal callback', (
    tester,
  ) async {
    final source = MockProcessingProgressSource();
    final controller = ProcessingController.fromProgressSource(source);
    addTearDown(controller.dispose);
    var returned = false;
    await tester.pumpWidget(
      _localizedApp(
        ProcessingScreen(
          session: CaptureSession(),
          controller: controller,
          onContinue: () => returned = true,
        ),
        locale: 'en',
      ),
    );
    await tester.pump();
    expect(find.text('0%'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Processing service connected'), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('stage-imagePreparation-active')),
      150,
    );
    expect(
      find.byKey(const ValueKey('stage-dataUpload-completed')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('stage-imagePreparation-active')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('stage-structureReconstruction-pending')),
      findsOneWidget,
    );
    for (var i = 1; i <= 5; i++) {
      source.advance();
      await tester.pump();
    }
    for (final stage in ProcessingStage.values) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey('stage-${stage.name}-completed')),
        100,
      );
    }
    await tester.scrollUntilVisible(find.text('Return'), -150);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Simulation completed'), findsOneWidget);
    expect(
      find.text('Progress will appear here when processing starts.'),
      findsNothing,
    );
    await tester.tap(find.text('Return'));
    expect(returned, isTrue);
  });

  testWidgets('failure shows error, stopped context and supported retry', (
    tester,
  ) async {
    final source = MockProcessingProgressSource(
      scenario: MockProcessingScenario.failure,
    );
    final controller = ProcessingController.fromProgressSource(source);
    addTearDown(controller.dispose);
    source.advance();
    source.advance();
    source.advance();
    await tester.pumpWidget(
      _localizedApp(
        ProcessingScreen(session: CaptureSession(), controller: controller),
        locale: 'en',
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text(
        'The simulation stopped while generating details. You can retry the demo.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(find.text('Stopped at this stage'), 150);
    await tester.scrollUntilVisible(find.text('Retry'), -150);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(controller.snapshot.progressPercent, 0);
    expect(controller.snapshot.failure, isNull);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets(
    'unknown progress and 100 percent remain running until explicit success',
    (tester) async {
      final session = CaptureSession();
      await tester.pumpWidget(
        _localizedApp(
          ProcessingScreen(
            session: session,
            snapshot: ProcessingSnapshot(status: ProcessingStatus.processing),
          ),
          locale: 'en',
        ),
      );
      await tester.pump();
      expect(find.textContaining('%'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(
        _localizedApp(
          ProcessingScreen(
            session: session,
            snapshot: ProcessingSnapshot(
              status: ProcessingStatus.processing,
              progressPercent: 100,
              provenance: ProgressProvenance.measured,
            ),
          ),
          locale: 'en',
        ),
      );
      expect(find.text('100%'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Return'), findsNothing);
      await tester.pumpWidget(
        _localizedApp(
          ProcessingScreen(
            session: session,
            snapshot: ProcessingSnapshot(
              status: ProcessingStatus.failed,
              errorMessage: 'Presentation-safe error',
            ),
          ),
          locale: 'en',
        ),
      );
      expect(find.text('Presentation-safe error'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  for (final locale in ['en', 'vi']) {
    testWidgets('$locale localizes demo failure and completion', (
      tester,
    ) async {
      final source = MockProcessingProgressSource(
        scenario: MockProcessingScenario.failure,
      );
      final controller = ProcessingController.fromProgressSource(source);
      addTearDown(controller.dispose);
      source.advance();
      source.advance();
      source.advance();
      await tester.pumpWidget(
        _localizedApp(
          ProcessingScreen(session: CaptureSession(), controller: controller),
          locale: locale,
        ),
      );
      await tester.pump();
      final context = tester.element(find.byType(ProcessingScreen));
      final strings = AppLocalizations.of(context)!;
      expect(find.text(strings.processingDemoFailure), findsOneWidget);
      expect(find.text(strings.processingSimulated), findsOneWidget);
      await tester.pumpWidget(
        _localizedApp(
          ProcessingScreen(
            session: CaptureSession(),
            snapshot: ProcessingSnapshot(
              status: ProcessingStatus.completed,
              provenance: ProgressProvenance.simulated,
              progressPercent: 100,
            ),
          ),
          locale: locale,
        ),
      );
      await tester.pump();
      expect(find.text(strings.processingDemoCompleted), findsOneWidget);
      expect(find.text(strings.processingDemoCompleteBody), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
    testWidgets('$locale at 320px and 2x text has no overflow in each state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = MockProcessingProgressSource(
        scenario: MockProcessingScenario.failure,
      );
      final controller = ProcessingController.fromProgressSource(source);
      addTearDown(controller.dispose);
      final session = CaptureSession();
      final states = [
        const ProcessingSnapshot.waiting(),
        controller.snapshot,
        ProcessingSnapshot(status: ProcessingStatus.processing),
        ProcessingSnapshot(
          status: ProcessingStatus.failed,
          errorMessage: 'A long presentation-safe error that must wrap without overflowing the available space.',
        ),
        ProcessingSnapshot(status: ProcessingStatus.completed),
      ];
      for (final state in states) {
        await tester.pumpWidget(
          _localizedApp(
            ProcessingScreen(session: session, snapshot: state),
            locale: locale,
            scale: 2,
          ),
        );
        await tester.pump();
        await tester.scrollUntilVisible(
          find.byKey(
            ValueKey(
              'stage-completion-${state.status == ProcessingStatus.completed ? 'completed' : 'pending'}',
            ),
          ),
          200,
        );
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(ListView), const Offset(0, 5000));
        await tester.pump();
      }
    });
  }
}

class _MemorySession extends CaptureSession {
  @override
  Future<CaptureSizeSummary> measureSize() async =>
      const CaptureSizeSummary(2048, 0);
}

Widget _localizedApp(Widget home, {String locale = 'vi', double scale = 1}) =>
    MaterialApp(
      locale: Locale(locale),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: home,
    );
