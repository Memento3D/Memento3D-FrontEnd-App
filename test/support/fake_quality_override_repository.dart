import 'dart:async';

import 'package:memento3d_frontend_app/features/scans/domain/models/quality_override_context.dart';
import 'package:memento3d_frontend_app/features/scans/domain/models/quality_override_outcome.dart';
import 'package:memento3d_frontend_app/features/scans/domain/repositories/quality_override_repository.dart';

class FakeQualityOverrideRepository implements QualityOverrideRepository {
  final List<QualityOverrideContext> _requests = [];
  final List<Completer<QualityOverrideOutcome>> _completers = [];

  int get requestCount => _requests.length;
  List<QualityOverrideContext> get requests => List.unmodifiable(_requests);

  @override
  Future<QualityOverrideOutcome> requestOverride(
    QualityOverrideContext context,
  ) {
    _requests.add(context);
    final completer = Completer<QualityOverrideOutcome>();
    _completers.add(completer);
    return completer.future;
  }

  void complete(int index, QualityOverrideOutcome outcome) {
    _completers[index].complete(outcome);
  }

  void fail(int index, Object error) {
    _completers[index].completeError(error);
  }
}
