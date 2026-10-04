import '../models/quality_override_context.dart';
import '../models/quality_override_outcome.dart';

abstract interface class QualityOverrideRepository {
  Future<QualityOverrideOutcome> requestOverride(
    QualityOverrideContext context,
  );
}
