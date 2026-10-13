import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memento3d_frontend_app/core/network/api_client.dart';
import 'package:memento3d_frontend_app/features/auth/data/services/auth_storage.dart';
import 'package:memento3d_frontend_app/features/uploads/data/api/photo_upload_api.dart';
import 'package:memento3d_frontend_app/features/uploads/data/dto/scan_image_upload_dto.dart';
import 'package:memento3d_frontend_app/features/uploads/data/local/local_photo_file.dart';
import 'package:memento3d_frontend_app/features/uploads/data/photo_upload_repository_impl.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/models/photo_upload_failure.dart';
import 'package:memento3d_frontend_app/features/uploads/domain/repositories/photo_upload_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const scanId = '11111111-2222-4333-8444-555555555555';
const imageId = 'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee';
Map<String, dynamic> success() => {
  'image': {
    'id': imageId,
    'scan_id': scanId,
    'original_filename': 'photo.jpg',
    'thumbnail_path': null,
    'file_size_bytes': 3,
    'mime_type': 'image/jpeg',
    'width': null,
    'height': null,
    'format': 'jpg',
    'sort_order': 2,
    'upload_status': 'uploaded',
    'is_excluded': false,
    'exclude_reason': null,
    'needs_quality_check': true,
    'created_at': '2026-10-13T00:00:00Z',
  },
  'scan_file_count': 3,
  'scan_total_size_bytes': 9,
};

class Photo implements PhotoUploadFile {
  Photo({this.filename = 'photo.jpg', this.size = 3, this.mimeType});
  @override
  final String filename;
  final int size;
  @override
  final String? mimeType;
  @override
  Future<int> length() async => size;
  @override
  Stream<List<int>> openRead() => Stream.value([1, 2, 3]);
}

class UploadClient extends http.BaseClient {
  int calls = 0;
  int status = 201;
  Object? body;
  Object? error;
  http.MultipartRequest? request;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest value) async {
    calls++;
    request = value as http.MultipartRequest;
    if (error != null) throw error!;
    return http.StreamedResponse(
      Stream.value(utf8.encode(jsonEncode(body ?? success()))),
      status,
    );
  }
}

Matcher failure(PhotoUploadFailureKind kind, {int? status}) =>
    isA<PhotoUploadFailure>()
        .having((e) => e.kind, 'kind', kind)
        .having((e) => e.statusCode, 'status', status);

void main() {
  test(
    'local adapter streams bytes and retains the original filename',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'photo_upload_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/camera.jpg');
      await file.writeAsBytes([1, 2, 3]);
      final photo = LocalPhotoFile(file.path, filename: 'original.JPG');
      expect(photo.filename, 'original.JPG');
      expect(await photo.length(), 3);
      expect(await photo.openRead().expand((bytes) => bytes).toList(), [
        1,
        2,
        3,
      ]);
    },
  );
  late UploadClient client;
  late PhotoUploadRepository repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthStorage.clearAuthData();
    await AuthStorage.saveToken('test-token');
    client = UploadClient();
    repository = PhotoUploadRepositoryImpl(
      PhotoUploadApi(ApiClient(client: client)),
    );
  });
  tearDown(() async {
    await AuthStorage.clearAuthData();
    ApiClient.onUnauthorized = null;
  });

  test(
    'one POST returns the persisted image with exact identities and fields',
    () async {
      final image = await repository.uploadPhoto(
        scanId: scanId,
        photo: Photo(),
      );
      expect(image.id, imageId);
      expect(image.scanId, scanId);
      expect(image.originalFilename, 'photo.jpg');
      expect(image.fileSizeBytes, 3);
      expect(image.mimeType, 'image/jpeg');
      expect(image.format, 'jpg');
      expect(image.sortOrder, 2);
      expect(image.uploadStatus, 'uploaded');
      expect(image.isExcluded, false);
      expect(image.excludeReason, isNull);
      expect(image.needsQualityCheck, true);
      expect(image.createdAt, DateTime.utc(2026, 10, 13));
      expect(image.thumbnailPath, isNull);
      expect(image.width, isNull);
      expect(image.height, isNull);
      expect(client.calls, 1);
      expect(client.request!.method, 'POST');
      expect(client.request!.url.path, '/api/v1/scans/$scanId/images');
      expect(client.request!.files.single.field, 'file');
      expect(client.request!.files.single.filename, 'photo.jpg');
      expect(client.request!.fields, isEmpty);
      expect(client.request!.headers['Authorization'], 'Bearer test-token');
    },
  );

  for (final extension in ['jpg', 'jpeg', 'png', 'JPG']) {
    test('accepts $extension and supplies the MIME label', () async {
      await repository.uploadPhoto(
        scanId: scanId,
        photo: Photo(filename: 'original.$extension'),
      );
      expect(client.request!.files.single.filename, 'original.$extension');
      expect(
        client.request!.files.single.contentType.toString(),
        extension == 'png' ? 'image/png' : 'image/jpeg',
      );
    });
  }
  test(
    'maximum inclusive boundary accepted without buffering a large fixture',
    () async {
      await repository.uploadPhoto(
        scanId: scanId,
        photo: Photo(size: 20971520),
      );
      expect(client.request!.files.single.length, 20971520);
    },
  );
  for (final photo in [
    Photo(size: 0),
    Photo(size: 20971521),
    Photo(filename: 'photo.gif'),
    Photo(filename: 'photo'),
    Photo(mimeType: 'text/plain'),
  ]) {
    test(
      'invalid local photo ${photo.filename}/${photo.size}/${photo.mimeType} never sent',
      () async {
        await expectLater(
          repository.uploadPhoto(scanId: scanId, photo: photo),
          throwsA(failure(PhotoUploadFailureKind.notSubmitted)),
        );
        expect(client.calls, 0);
      },
    );
  }
  test('invalid scan ID never sent', () async {
    await expectLater(
      repository.uploadPhoto(scanId: '../bad', photo: Photo()),
      throwsA(failure(PhotoUploadFailureKind.notSubmitted)),
    );
    expect(client.calls, 0);
  });
  for (final error in [
    const SocketException('disconnect'),
    TimeoutException('timeout'),
    http.ClientException('lost'),
  ]) {
    test('transport $error is ambiguous and never replayed', () async {
      client.error = error;
      await expectLater(
        repository.uploadPhoto(scanId: scanId, photo: Photo()),
        throwsA(
          isA<PhotoUploadFailure>().having(
            (e) => e.kind,
            'kind',
            PhotoUploadFailureKind.ambiguous,
          ),
        ),
      );
      expect(client.calls, 1);
    });
  }
  for (final status in [400, 401, 403, 404, 409, 413, 408, 500, 502]) {
    test('HTTP $status is conservatively classified without replay', () async {
      client.status = status;
      client.body = {'message': 'Rejected'};
      await expectLater(
        repository.uploadPhoto(scanId: scanId, photo: Photo()),
        throwsA(
          failure(
            status == 408 || status >= 500
                ? PhotoUploadFailureKind.ambiguous
                : PhotoUploadFailureKind.rejected,
            status: status,
          ),
        ),
      );
      expect(client.calls, 1);
    });
  }
  test('unexpected 2xx and malformed success remain ambiguous', () async {
    client.status = 200;
    await expectLater(
      repository.uploadPhoto(scanId: scanId, photo: Photo()),
      throwsA(failure(PhotoUploadFailureKind.ambiguous, status: 200)),
    );
    client.status = 201;
    client.body = {'image': {}};
    await expectLater(
      repository.uploadPhoto(scanId: scanId, photo: Photo()),
      throwsA(failure(PhotoUploadFailureKind.ambiguous)),
    );
    expect(client.calls, 2); // Two explicit calls, never an internal replay.
  });
  test('wrong scan or unconfirmed status in success is ambiguous', () async {
    for (final change in [
      {'scan_id': imageId},
      {'upload_status': 'pending'},
    ]) {
      final body = success();
      (body['image'] as Map<String, dynamic>).addAll(change);
      client.body = body;
      await expectLater(
        repository.uploadPhoto(scanId: scanId, photo: Photo()),
        throwsA(failure(PhotoUploadFailureKind.ambiguous)),
      );
    }
  });
  test('DTO preserves nullable and populated backend metadata', () {
    final body = success();
    (body['image'] as Map<String, dynamic>).addAll({
      'width': 100,
      'height': 200,
      'thumbnail_path': 'opaque-reference',
      'is_excluded': true,
      'exclude_reason': 'reason',
    });
    final dto = ScanImageUploadDto.fromJson(body);
    expect(dto.scanFileCount, 3);
    expect(dto.scanTotalSizeBytes, 9);
    final image = dto.image.toDomain();
    expect(image.width, 100);
    expect(image.height, 200);
    expect(image.thumbnailPath, 'opaque-reference');
    expect(image.isExcluded, true);
    expect(image.excludeReason, 'reason');
  });
  for (final badId in [null, '', 'fixture-id', 42]) {
    test('DTO rejects bad image identity $badId', () {
      final body = success();
      (body['image'] as Map<String, dynamic>)['id'] = badId;
      expect(() => ScanImageUploadDto.fromJson(body), throwsFormatException);
    });
  }
  for (final field in [
    'scan_id',
    'file_size_bytes',
    'is_excluded',
    'needs_quality_check',
    'created_at',
  ]) {
    test('DTO rejects missing required $field', () {
      final body = success();
      (body['image'] as Map<String, dynamic>).remove(field);
      expect(() => ScanImageUploadDto.fromJson(body), throwsFormatException);
    });
  }
  for (final body in [
    null,
    [],
    'raw',
    {},
    {'image': null},
  ]) {
    test('DTO rejects malformed envelope $body', () {
      expect(() => ScanImageUploadDto.fromJson(body), throwsFormatException);
    });
  }
}
