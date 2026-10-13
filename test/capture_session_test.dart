import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/screens/capture_session.dart';

void main() {
  test('persisted identity survives photo and detail changes', () {
    const scanId = '11111111-2222-4333-8444-555555555555';
    final session = CaptureSession(scanId: scanId);
    final photo = XFile('local.jpg');
    session.addPhoto(photo);
    session.detailLevel = ReconstructionDetailLevel.standard;
    session.removePhoto(photo);
    expect(session.scanId, scanId);
  });

  test(
    'blank persisted identities are rejected; local previews remain valid',
    () {
      expect(() => CaptureSession(scanId: ''), throwsArgumentError);
      expect(() => CaptureSession(scanId: '   '), throwsArgumentError);
      expect(CaptureSession().scanId, isNull);
    },
  );

  test('review eligibility and count follow the photo collection', () {
    final session = CaptureSession();
    expect(session.canReview, isFalse);
    expect(session.photoCount, 0);
    final first = XFile('first.jpg');
    session.addPhoto(first);
    expect(session.canReview, isTrue);
    expect(session.photoCount, 1);
    expect(session.latestPhoto, same(first));
  });

  test('file size and summary update after removing a photo', () async {
    final directory = await Directory.systemTemp.createTemp('capture_review_');
    addTearDown(() => directory.delete(recursive: true));
    final firstFile = File('${directory.path}/first.jpg');
    final secondFile = File('${directory.path}/second.jpg');
    await firstFile.writeAsBytes(List.filled(1024, 1));
    await secondFile.writeAsBytes(List.filled(2048, 2));

    final session = CaptureSession();
    final first = XFile(firstFile.path);
    final second = XFile(secondFile.path);
    session.addPhoto(first);
    session.addPhoto(second);
    expect((await session.measureSize()).bytes, 3072);

    session.removePhoto(first);
    expect(session.photoCount, 1);
    expect(session.latestPhoto, same(second));
    expect((await session.measureSize()).bytes, 2048);
    expect(await firstFile.exists(), isTrue);
  });

  test('missing image is excluded from size and counted unavailable', () async {
    final session = CaptureSession();
    session.addPhoto(XFile('missing_review_photo.jpg'));
    final summary = await session.measureSize();
    expect(summary.bytes, 0);
    expect(summary.unavailableFiles, 1);
  });

  test('detail selection remains on the same session', () {
    final session = CaptureSession();
    expect(session.detailLevel, ReconstructionDetailLevel.highDetail);
    session.detailLevel = ReconstructionDetailLevel.standard;
    expect(session.detailLevel, ReconstructionDetailLevel.standard);
  });
}
