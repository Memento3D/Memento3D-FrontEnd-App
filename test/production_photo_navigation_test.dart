import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/home/presentation/screens/main_screen.dart';
import 'package:memento3d_frontend_app/features/scans/data/models/scan_item.dart';
import 'package:memento3d_frontend_app/features/scans/data/repositories/scan_repository.dart';
import 'package:memento3d_frontend_app/features/scans/data/services/scan_service.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/dashboard_screen.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/screens/scan_wizard_screen.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/widgets/create_scan_dialog.dart';
import 'package:memento3d_frontend_app/l10n/app_localizations.dart';
import 'package:memento3d_frontend_app/screens/camera_screen.dart';

const backendId = '3baf6209-96d2-43b3-854e-054cab092560';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Client client;
  late Completer<http.Response> creation;
  var posts = 0;
  var mode = 'image';
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    posts = 0;
    mode = 'image';
    client = _Client((request) async {
      if (request.method == 'POST') {
        expect(request.url.path, '/api/v1/scans');
        posts++;
        mode =
            (jsonDecode((request as http.Request).body)
                    as Map<String, dynamic>)['input_mode']
                as String;
        return creation.future;
      }
      return http.Response('{"scans":[]}', 200);
    });
    ScanRepository.instance.clear();
    ScanRepository.instance.setService(
      ScanService(apiClient: ApiClient(client: client)),
    );
    // Serve bundled font bytes under the variants GoogleFonts requests. No network.
    GoogleFonts.config.allowRuntimeFetching = false;
    final bytes = ByteData.sublistView(
      File('assets/fonts/PlusJakartaSans.ttf').readAsBytesSync(),
    );
    final variants = [
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
      'Light',
      'ExtraLight',
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(
            message!.buffer.asUint8List(
              message.offsetInBytes,
              message.lengthInBytes,
            ),
          );
          if (key == 'AssetManifest.bin') {
            return const StandardMessageCodec().encodeMessage({
              for (final v in variants)
                'assets/fonts/PlusJakartaSans-$v.ttf': [
                  {'asset': 'assets/fonts/PlusJakartaSans-$v.ttf'},
                ],
            });
          }
          if (key.startsWith('assets/fonts/PlusJakartaSans-')) return bytes;
          final file = File(key);
          return file.existsSync()
              ? ByteData.sublistView(file.readAsBytesSync())
              : null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/camera'),
          (call) async =>
              call.method == 'availableCameras' ? <dynamic>[] : null,
        );
  });
  tearDown(() {
    client.close();
    ScanRepository.instance.clear();
    ScanRepository.instance.setService(ScanService());
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/camera'),
          null,
        );
  });

  Future<void> launch(WidgetTester tester, bool main) async {
    creation = Completer<http.Response>();
    final report = FlutterError.onError;
    // Existing offstage HomeTab tiles emit a decoration diagnostic unrelated
    // to navigation. Keep every other framework error visible to these tests.
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains(
        'ListTile background color or ink splashes may be invisible.',
      )) {
        return;
      }
      report?.call(details);
    };
    addTearDown(() => FlutterError.onError = report);

    tester.view.physicalSize = const Size(800, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [_HandoffObserver()],
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: main ? const MainScreen() : const DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();
    if (main) {
      await tester.tap(
        find
            .ancestor(
              of: find.byIcon(Icons.add_rounded).last,
              matching: find.byType(GestureDetector),
            )
            .first,
      );
    } else {
      await tester.tap(find.byType(FloatingActionButton));
    }
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, {bool video = false}) async {
    final dialog = find.byType(CreateScanDialog);
    await tester.enterText(
      find.descendant(of: dialog, matching: find.byType(TextFormField)).first,
      'Upload Test 108',
    );
    if (video) await tester.tap(find.text('Quay Video'));
    final button = find.descendant(
      of: dialog,
      matching: find.byType(ElevatedButton),
    );
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump();
    expect(posts, 1);
  }

  void complete() => creation.complete(
    http.Response(
      jsonEncode({
        'id': backendId,
        'name': 'Upload Test 108',
        'input_mode': mode,
        'status': 'draft',
        'file_count': 0,
        'total_size_bytes': 0,
        'created_at': '2026-10-13T00:00:00Z',
      }),
      201,
    ),
  );

  for (final main in [false, true]) {
    final entry = main ? 'MainScreen navigation bar' : 'production Dashboard';
    testWidgets('$entry photo creation preserves ID and creates once', (
      tester,
    ) async {
      await launch(tester, main);
      await submit(tester);
      complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(CreateScanDialog), findsNothing);
      final wizard = tester.widget<ScanWizardScreen>(
        find.byType(ScanWizardScreen),
      );
      expect(wizard.scanId, backendId);
      // Let the existing success snackbar leave the wizard's footer unobscured.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      // Exercise the real wizard's completion control.
      for (var i = 0; i < 4; i++) {
        final checkbox = find.byType(Checkbox).at(i);
        await tester.ensureVisible(checkbox);
        await tester.tap(checkbox);
        await tester.pump();
      }
      for (var i = 0; i < 4; i++) {
        final next = find
            .descendant(
              of: find.byType(ScanWizardScreen),
              matching: find.byType(ElevatedButton),
            )
            .last;
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      expect(
        tester.widget<CameraScreen>(find.byType(CameraScreen)).session.scanId,
        backendId,
      );
      expect(ScanRepository.instance.cachedScans.single.id, backendId);
      expect(posts, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
    testWidgets('$entry cancellation does not navigate or create', (
      tester,
    ) async {
      await launch(tester, main);
      Navigator.of(tester.element(find.byType(CreateScanDialog))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(ScanWizardScreen), findsNothing);
      expect(find.byType(CameraScreen), findsNothing);
      expect(posts, 0);
    });
    testWidgets('$entry dismissal during creation never opens capture', (
      tester,
    ) async {
      await launch(tester, main);
      await submit(tester);
      Navigator.of(tester.element(find.byType(CreateScanDialog))).pop();
      await tester.pumpAndSettle();
      complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(ScanWizardScreen), findsNothing);
      expect(find.byType(CameraScreen), findsNothing);
      expect(posts, 1);
    });
    testWidgets('$entry video creation keeps dashboard behavior', (
      tester,
    ) async {
      await launch(tester, main);
      await submit(tester, video: true);
      complete();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(CreateScanDialog), findsNothing);
      expect(find.byType(ScanWizardScreen), findsNothing);
      expect(find.byType(CameraScreen), findsNothing);
      expect(posts, 1);
      expect(
        ScanRepository.instance.cachedScans.single.inputMode,
        ScanInputMode.video,
      );
    });
  }
}

class _HandoffObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is MaterialPageRoute && previousRoute != null) {
      expect(find.byType(CreateScanDialog, skipOffstage: false), findsNothing);
    }
    super.didPush(route, previousRoute);
  }
}

class _Client extends http.BaseClient {
  _Client(this.handler);
  final Future<http.Response> Function(http.BaseRequest) handler;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
    );
  }
}
