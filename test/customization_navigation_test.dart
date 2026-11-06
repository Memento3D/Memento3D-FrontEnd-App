import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/customization/presentation/create_model_screen.dart';
import 'package:memento3d_frontend_app/features/customization/presentation/customization_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'finished job opens customization once and back returns to list',
    (tester) async {
      var polls = 0, scenes = 0;
      final client = MockClient((request) async {
        switch (request.url.path) {
          case '/api/v1/reconstruction-jobs/job':
            polls++;
            return http.Response(
              jsonEncode({
                'job_id': 'job',
                'status': 'done',
                'execution_mode': 'real',
                'progress': 100,
              }),
              200,
            );
          case '/api/v1/reconstruction-jobs/job/outputs':
            return http.Response('[{"output_id":"out","format":"glb"}]', 200);
          case '/api/v1/models/out/scene':
            scenes++;
            return http.Response('{"message":"Temporarily unavailable"}', 503);
          default:
            throw StateError('Unexpected endpoint ${request.url}');
        }
      });
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ModelProgressScreen(
                      scanId: 'scan',
                      jobId: 'job',
                      api: ApiClient(client: client),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(CustomizationScreen), findsOneWidget);
      expect(polls, 1);
      expect(scenes, 1);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Open'), findsOneWidget);
      expect(find.byType(ModelProgressScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'failed job is terminal, never fetches model or starts another job',
    (tester) async {
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        expect(request.method, 'GET');
        return http.Response(
          '{"job_id":"job","status":"failed","execution_mode":"real","error_message":"Input rejected"}',
          200,
        );
      });
      addTearDown(client.close);
      await tester.pumpWidget(
        MaterialApp(
          home: ModelProgressScreen(
            scanId: 'scan',
            jobId: 'job',
            api: ApiClient(client: client),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 8));
      expect(find.text('Input rejected'), findsOneWidget);
      expect(paths, ['/api/v1/reconstruction-jobs/job']);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
