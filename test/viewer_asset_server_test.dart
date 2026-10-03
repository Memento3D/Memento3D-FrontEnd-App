import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/model_viewer/presentation/services/viewer_asset_server.dart';

class _Bundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key != 'assets/model_viewer/index.html' && key != 'assets/test.glb') {
      throw StateError('missing');
    }
    return ByteData.sublistView(Uint8List.fromList([1, 2, 3, 4]));
  }
}

void main() {
  test(
    'serves only registered bundled assets with exact byte length',
    () async {
      final server = ViewerAssetServer(bundle: _Bundle());
      final client = HttpClient();
      await server.start();
      addTearDown(() async {
        client.close(force: true);
        await server.close();
      });
      final url = server.resolveModelUrl('asset:///assets/test.glb', '1');
      final response = await (await client.getUrl(Uri.parse(url))).close();
      expect(response.statusCode, 200);
      expect(response.contentLength, 4);
      expect(await response.expand((bytes) => bytes).toList(), [1, 2, 3, 4]);
      for (final denied in [
        server.page.resolve('secret.glb'),
        server.page.replace(path: '/index.html'),
      ]) {
        final response = await (await client.getUrl(denied)).close();
        expect(response.statusCode, 404);
        await response.drain<void>();
      }
      expect(
        () => server.resolveModelUrl('file:///private/data.glb', '2'),
        throwsFormatException,
      );
      expect(
        () => server.resolveModelUrl('http://example.test/data.glb', '2'),
        throwsFormatException,
      );
      expect(
        server.resolveModelUrl('https://example.test/a.glb', '2'),
        'https://example.test/a.glb',
      );
    },
  );
}
