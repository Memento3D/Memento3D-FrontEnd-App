import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/core/network/api_exception.dart';
import 'package:memento3d_frontend_app/features/customization/data/customization_api.dart';

Map<String, dynamic> draft() => {
  'modelOutputId': 'out',
  'fitResultId': 'fit',
  'revision': 0,
  'exists': false,
  'editable': true,
  'selection': {'headwear': 'cap', 'glasses': null},
};
Map<String, dynamic> scene() => {
  'modelOutputId': 'out',
  'fitResultId': 'fit',
  'baseModel': {'url': 'https://example.com/base.glb', 'sha256': 'base'},
  'assets': [
    for (final id in ['cap', 'hair', 'glass'])
      {
        'assetVersionId': id,
        'sha256': id,
        'url': 'https://example.com/$id.glb',
        'matrixColumnMajor': [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
      },
  ],
  'groups': [
    {
      'id': 'headwear',
      'required': true,
      'noneAllowed': false,
      'assetVersionIds': ['cap', 'hair'],
    },
    {
      'id': 'glasses',
      'required': false,
      'noneAllowed': true,
      'assetVersionIds': ['glass'],
    },
  ],
  'customization': draft(),
};

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('scene validates mutual exclusion, allowed IDs and fitted matrices', () {
    final value = DesignScene.fromJson(scene());
    expect(value.accepts({'headwear': 'hair', 'glasses': 'glass'}), true);
    expect(value.accepts({'headwear': null, 'glasses': null}), false);
    expect(value.accepts({'headwear': 'random', 'glasses': null}), false);
    expect(
      value.accepts({'headwear': 'cap', 'glasses': null, 'unknown': null}),
      false,
    );
    final invalid = scene();
    (invalid['assets'] as List).first['matrixColumnMajor'] = [1];
    expect(() => DesignScene.fromJson(invalid), throwsFormatException);
  });
  test(
    'save uses output ID, original revision and selection JSON only',
    () async {
      final client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/v1/models/out/customization');
        expect(jsonDecode(request.body), {
          'fitResultId': 'fit',
          'revision': 0,
          'selection': {'headwear': 'hair', 'glasses': null},
        });
        return http.Response(
          jsonEncode({
            ...draft(),
            'revision': 1,
            'exists': true,
            'selection': {'headwear': 'hair', 'glasses': null},
          }),
          200,
        );
      });
      addTearDown(client.close);
      final api = CustomizationApi(client: ApiClient(client: client));
      final saved = await api.save('out', DesignDraft.fromJson(draft()), {
        'headwear': 'hair',
        'glasses': null,
      });
      expect(saved.revision, 1);
      expect(saved.selection['headwear'], 'hair');
    },
  );
  test(
    '409 preserves backend code for explicit restore instead of blind retry',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return http.Response(
          '{"code":"CUSTOMIZATION_REVISION_CONFLICT","message":"Conflict"}',
          409,
        );
      });
      addTearDown(client.close);
      final api = CustomizationApi(client: ApiClient(client: client));
      await expectLater(
        api.save('out', DesignDraft.fromJson(draft()), {
          'headwear': 'hair',
          'glasses': null,
        }),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 409)
              .having(
                (e) => e.backendCode,
                'code',
                'CUSTOMIZATION_REVISION_CONFLICT',
              ),
        ),
      );
      expect(requests, 1);
    },
  );
}
