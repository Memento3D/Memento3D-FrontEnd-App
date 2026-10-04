import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/core/utils/error_mapper.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/job_model.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/job_service.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/job_failed_screen.dart';
import 'package:memento3d_frontend_app/screens/processing_screen.dart';

class FakeJobService extends JobService {
  FakeJobService({this.result, this.error});

  final JobModel? result;
  final Object? error;
  final List<String> retryIds = [];
  int retryCalls = 0;

  @override
  Future<JobModel> retryJob(String jobId) async {
    retryCalls++;
    retryIds.add(jobId);
    if (error != null) throw error!;
    return result!;
  }
}

Widget _app(Widget home, {NavigatorObserver? observer}) => MaterialApp(
  locale: const Locale('vi'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  navigatorObservers: [?observer],
  home: home,
);

void main() {
  testWidgets('displays backend error_message and friendly fallback', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2400);
    await tester.pumpWidget(
      _app(
        JobFailedScreen(
          jobId: 'job-1',
          errorMessage: 'timeout when uploading',
          jobService: FakeJobService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // technical message mapped to friendly text
    expect(
      find.text(ErrorMapper.friendlyJobErrorMessage('timeout when uploading')),
      findsOneWidget,
    );

    await tester.pumpWidget(
      _app(
        JobFailedScreen(
          jobId: 'job-1',
          errorMessage: null,
          jobService: FakeJobService(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text(ErrorMapper.friendlyJobErrorMessage(null)),
      findsOneWidget,
    );
  });

  testWidgets('retry loading state and duplicate taps are prevented', (
    tester,
  ) async {
    final service = FakeJobService(
      result: JobModel(id: 'new-job', status: JobStatus.running, progress: 0.0),
    );
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2400);
    await tester.pumpWidget(
      _app(JobFailedScreen(jobId: 'job-1', jobService: service)),
    );
    await tester.pumpAndSettle();

    final strings = AppLocalizations.of(
      tester.element(find.byType(JobFailedScreen)),
    )!;
    await tester.tap(find.text(strings.jobRetry));
    await tester.pump();
    expect(find.text(strings.jobRetrying), findsOneWidget);
    await tester.tap(find.text(strings.jobRetrying));
    await tester.pump();
    expect(service.retryCalls, 1);
    await tester.pumpAndSettle();
  });

  testWidgets('successful retry uses returned job id and navigates', (
    tester,
  ) async {
    final service = FakeJobService(
      result: JobModel(
        id: 'new-job-42',
        status: JobStatus.running,
        progress: 0.15,
      ),
    );
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2400);
    await tester.pumpWidget(
      _app(JobFailedScreen(jobId: 'job-1', jobService: service)),
    );
    await tester.pumpAndSettle();

    final strings = AppLocalizations.of(
      tester.element(find.byType(JobFailedScreen)),
    )!;
    await tester.tap(find.text(strings.jobRetry));
    await tester.pumpAndSettle();

    expect(service.retryIds, ['job-1']);
    final screen = tester.widget<ProcessingScreen>(
      find.byType(ProcessingScreen),
    );
    expect(screen.snapshot.jobId, 'new-job-42');
  });

  testWidgets('HTTP 400 hides retry button and shows alternative', (
    tester,
  ) async {
    final service = FakeJobService(
      error: ApiException(
        statusCode: 400,
        errorCode: 'ERR-009',
        message: 'Retry limit reached',
      ),
    );
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2400);
    await tester.pumpWidget(
      _app(JobFailedScreen(jobId: 'job-1', jobService: service)),
    );
    await tester.pumpAndSettle();

    final strings = AppLocalizations.of(
      tester.element(find.byType(JobFailedScreen)),
    )!;
    await tester.tap(find.text(strings.jobRetry));
    await tester.pumpAndSettle();

    expect(find.text(strings.jobRetry), findsNothing);
    expect(find.text(strings.jobRetryLimit), findsOneWidget);
  });

  testWidgets('network failure keeps retry available', (tester) async {
    final service = FakeJobService(
      error: ApiException(
        statusCode: 0,
        errorCode: 'ERR-017',
        message: 'no connection',
      ),
    );
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2400);
    await tester.pumpWidget(
      _app(JobFailedScreen(jobId: 'job-1', jobService: service)),
    );
    await tester.pumpAndSettle();

    final strings = AppLocalizations.of(
      tester.element(find.byType(JobFailedScreen)),
    )!;
    await tester.tap(find.text(strings.jobRetry));
    await tester.pumpAndSettle();

    expect(find.text(strings.jobRetry), findsOneWidget);
    expect(find.text(strings.jobRetryFailedHint), findsOneWidget);
  });

  testWidgets('dashboard button navigates back to first route', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(800, 2400);
    await tester.pumpWidget(_app(const Scaffold(body: Text('Dashboard Home'))));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(
      MaterialPageRoute(
        builder: (_) =>
            JobFailedScreen(jobId: 'job-1', jobService: FakeJobService()),
      ),
    );
    await tester.pumpAndSettle();

    final strings = AppLocalizations.of(
      tester.element(find.byType(JobFailedScreen)),
    )!;
    await tester.tap(find.text(strings.jobDashboard));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Home'), findsOneWidget);
  });
}
