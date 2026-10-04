import 'package:flutter_test/flutter_test.dart';
import 'package:memento3d_frontend_app/features/scans/domain/models/quality_override_context.dart';
import 'package:memento3d_frontend_app/features/scans/domain/models/quality_override_outcome.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/controllers/quality_override_controller.dart';
import 'package:memento3d_frontend_app/features/scans/presentation/controllers/quality_override_state.dart';

import 'support/fake_quality_override_repository.dart';

QualityOverrideContext context({
  String scanId = 'scan',
  String qualityRunId = 'run',
  QualityClassification classification = QualityClassification.amber,
  double score = 75,
}) => QualityOverrideContext(
  scanId: scanId,
  qualityRunId: qualityRunId,
  classification: classification,
  qualifiedImageCount: 12,
  affectedImageCount: 3,
  overallQualityPercentage: score,
);

void main() {
  late FakeQualityOverrideRepository repository;
  late QualityOverrideController controller;

  setUp(() {
    repository = FakeQualityOverrideRepository();
    controller = QualityOverrideController(
      repository: repository,
      context: context(),
    );
  });
  tearDown(() => controller.dispose());

  test('eligible AMBER starts unacknowledged', () {
    expect(controller.state.status, QualityOverrideStatus.unacknowledged);
    expect(controller.state.canAcknowledge, isTrue);
    expect(controller.state.canSubmit, isFalse);
  });

  test('submit before acknowledgement makes zero requests', () async {
    await controller.submit();
    expect(repository.requestCount, 0);
  });

  test('acknowledgement enables submission and preserves input', () async {
    final snapshot = controller.state;
    controller.acknowledge();
    expect(controller.state.canSubmit, isTrue);
    expect(snapshot.status, QualityOverrideStatus.unacknowledged);
    final pending = controller.submit();
    expect(repository.requests.single, same(snapshot.context));
    expect(repository.requests.single.scanId, 'scan');
    expect(repository.requests.single.qualityRunId, 'run');
    expect(() => repository.requests.clear(), throwsUnsupportedError);
    repository.complete(0, QualityOverrideOutcome.success);
    await pending;
  });

  for (final classification in [
    QualityClassification.red,
    QualityClassification.green,
    QualityClassification.unknown,
  ]) {
    test('$classification cannot acknowledge or submit', () async {
      controller.updateContext(context(classification: classification));
      controller.acknowledge();
      await controller.submit();
      expect(controller.state.status, QualityOverrideStatus.ineligible);
      expect(controller.state.canAcknowledge, isFalse);
      expect(controller.state.canSubmit, isFalse);
      expect(controller.state.isBlocked, isTrue);
      expect(repository.requestCount, 0);
    });
  }

  for (final input in [
    context(scanId: ''),
    context(qualityRunId: ''),
    context(scanId: '  '),
    context(qualityRunId: '\t'),
  ]) {
    test(
      'missing identifier ${input.scanId}/${input.qualityRunId} blocks submission',
      () async {
        controller.updateContext(input);
        controller.acknowledge();
        await controller.submit();
        expect(controller.state.isBlocked, isTrue);
        expect(repository.requestCount, 0);
      },
    );
  }

  test('scores do not determine eligibility', () {
    for (final score in [0.0, 100.0]) {
      controller.updateContext(context(score: score));
      expect(controller.state.canAcknowledge, isTrue);
    }
    controller.updateContext(
      context(classification: QualityClassification.red, score: 100),
    );
    expect(controller.state.canAcknowledge, isFalse);
  });

  test('concurrent and listener submits produce one request', () async {
    controller.acknowledge();
    controller.addListener(() {
      if (controller.state.isSubmitting) {
        controller.submit();
      }
    });
    final first = controller.submit();
    await controller.submit();
    expect(controller.state.isSubmitting, isTrue);
    expect(repository.requestCount, 1);
    repository.complete(0, QualityOverrideOutcome.success);
    await first;
  });

  test(
    'success emits once and cannot resubmit even after revisiting',
    () async {
      var successes = 0;
      controller.addListener(() {
        if (controller.state.status == QualityOverrideStatus.success) {
          successes++;
        }
      });
      controller.acknowledge();
      final pending = controller.submit();
      repository.complete(0, QualityOverrideOutcome.success);
      await pending;
      expect(controller.state.status, QualityOverrideStatus.success);
      controller.acknowledge();
      await controller.submit();
      controller.updateContext(context(qualityRunId: 'other'));
      controller.updateContext(context());
      expect(controller.state.status, QualityOverrideStatus.completed);
      controller.acknowledge();
      await controller.submit();
      expect(successes, 1);
      expect(repository.requestCount, 1);
    },
  );

  test('rejection permanently blocks the run across context changes', () async {
    controller.acknowledge();
    final pending = controller.submit();
    repository.complete(0, QualityOverrideOutcome.rejected);
    await pending;
    expect(controller.state.isBlocked, isTrue);
    controller.acknowledge();
    await controller.submit();
    controller.updateContext(context(qualityRunId: 'other'));
    controller.updateContext(context());
    expect(controller.state.status, QualityOverrideStatus.rejected);
    controller.acknowledge();
    await controller.submit();
    expect(repository.requestCount, 1);
  });

  test(
    'recoverable failure permits explicit retry for acknowledged run',
    () async {
      controller.acknowledge();
      final first = controller.submit();
      repository.complete(0, QualityOverrideOutcome.recoverableFailure);
      await first;
      expect(controller.state.status, QualityOverrideStatus.recoverableFailure);
      expect(controller.state.canSubmit, isTrue);
      expect(repository.requestCount, 1);
      final retry = controller.submit();
      expect(repository.requests[1], same(repository.requests[0]));
      repository.complete(1, QualityOverrideOutcome.success);
      await retry;
      expect(controller.state.status, QualityOverrideStatus.success);
    },
  );

  test('raw repository errors become recoverable failure', () async {
    controller.acknowledge();
    final pending = controller.submit();
    repository.fail(0, StateError('private transport details'));
    await pending;
    expect(controller.state.status, QualityOverrideStatus.recoverableFailure);
    expect(controller.state.canSubmit, isTrue);
  });

  for (final next in [
    context(scanId: 'other'),
    context(qualityRunId: 'other'),
    context(),
  ]) {
    test(
      'context replacement ${next.scanId}/${next.qualityRunId} clears acknowledgement',
      () async {
        controller.acknowledge();
        controller.updateContext(next);
        expect(controller.state.status, QualityOverrideStatus.unacknowledged);
        await controller.submit();
        expect(repository.requestCount, 0);
      },
    );
  }

  for (final outcome in QualityOverrideOutcome.values) {
    test('stale $outcome cannot change current state', () async {
      controller.acknowledge();
      final old = controller.submit();
      controller.updateContext(context(qualityRunId: 'new'));
      controller.acknowledge();
      final current = controller.submit();
      final snapshot = controller.state;
      repository.complete(0, outcome);
      await old;
      expect(controller.state, same(snapshot));
      repository.complete(1, QualityOverrideOutcome.success);
      await current;
      expect(controller.state.context.qualityRunId, 'new');
      expect(controller.state.status, QualityOverrideStatus.success);
    });
  }

  test('returning to a pending run cannot create duplicate requests', () async {
    controller.acknowledge();
    final pending = controller.submit();
    controller.updateContext(context(qualityRunId: 'other'));
    controller.updateContext(context());
    controller.acknowledge();
    await controller.submit();
    expect(repository.requestCount, 1);
    repository.complete(0, QualityOverrideOutcome.rejected);
    await pending;
    await controller.submit();
    expect(repository.requestCount, 1);
    controller.updateContext(context());
    expect(controller.state.isBlocked, isTrue);
  });

  test(
    'pending rejection immediately blocks a revisited logical run',
    () async {
      controller.acknowledge();
      final pending = controller.submit();
      controller.updateContext(context(qualityRunId: 'other'));
      final revisited = context(score: 80);
      controller.updateContext(revisited);
      expect(controller.state.status, QualityOverrideStatus.unacknowledged);
      controller.acknowledge();
      expect(controller.state.canSubmit, isTrue);
      repository.complete(0, QualityOverrideOutcome.rejected);
      await pending;
      expect(controller.state.context, same(revisited));
      expect(controller.state.status, QualityOverrideStatus.rejected);
      expect(controller.state.isBlocked, isTrue);
      expect(controller.state.canSubmit, isFalse);
      controller.acknowledge();
      await controller.submit();
      expect(repository.requestCount, 1);
    },
  );

  for (final next in [
    context(scanId: 'other'),
    context(qualityRunId: 'other'),
  ]) {
    test(
      'obsolete rejection preserves ${next.scanId}/${next.qualityRunId}',
      () async {
        controller.acknowledge();
        final pending = controller.submit();
        controller.updateContext(next);
        controller.acknowledge();
        final snapshot = controller.state;
        repository.complete(0, QualityOverrideOutcome.rejected);
        await pending;
        expect(controller.state, same(snapshot));
        expect(controller.state.canSubmit, isTrue);
        controller.updateContext(context());
        expect(controller.state.status, QualityOverrideStatus.rejected);
        expect(controller.state.isBlocked, isTrue);
        expect(controller.state.canSubmit, isFalse);
        await controller.submit();
        expect(repository.requestCount, 1);
      },
    );
  }

  test('pending stale success cannot continue a revisited run', () async {
    var successes = 0;
    controller.addListener(() {
      if (controller.state.status == QualityOverrideStatus.success) successes++;
    });
    controller.acknowledge();
    final pending = controller.submit();
    controller.updateContext(context(qualityRunId: 'other'));
    controller.updateContext(context());
    controller.acknowledge();
    final snapshot = controller.state;
    repository.complete(0, QualityOverrideOutcome.success);
    await pending;
    expect(controller.state, same(snapshot));
    expect(successes, 0);
    await controller.submit();
    expect(repository.requestCount, 1);
    controller.updateContext(context());
    expect(controller.state.status, QualityOverrideStatus.completed);
    expect(controller.state.canSubmit, isFalse);
    expect(successes, 0);
  });

  test(
    'failure acknowledgement does not survive context replacement',
    () async {
      controller.acknowledge();
      final pending = controller.submit();
      repository.complete(0, QualityOverrideOutcome.recoverableFailure);
      await pending;
      controller.updateContext(context());
      await controller.submit();
      expect(controller.state.canSubmit, isFalse);
      expect(repository.requestCount, 1);
    },
  );

  test('listener context replacement prevents submitting old input', () async {
    controller.acknowledge();
    controller.addListener(() {
      if (controller.state.isSubmitting) {
        controller.updateContext(context(qualityRunId: 'new'));
      }
    });
    await controller.submit();
    expect(repository.requestCount, 0);
    expect(controller.state.context.qualityRunId, 'new');
  });

  test(
    'completion after dispose cannot emit success or notifications',
    () async {
      final disposedController = QualityOverrideController(
        repository: repository,
        context: context(),
      );
      disposedController.acknowledge();
      final pending = disposedController.submit();
      var notifications = 0;
      disposedController.addListener(() => notifications++);
      final snapshot = disposedController.state;
      disposedController.dispose();
      repository.complete(0, QualityOverrideOutcome.success);
      await pending;
      disposedController.updateContext(context(qualityRunId: 'new'));
      disposedController.acknowledge();
      await disposedController.submit();
      expect(disposedController.state, same(snapshot));
      expect(notifications, 0);
      expect(repository.requestCount, 1);
    },
  );
}
