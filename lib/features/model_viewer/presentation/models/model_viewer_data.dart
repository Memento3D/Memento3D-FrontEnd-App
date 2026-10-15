import 'package:flutter/foundation.dart';

enum ModelAvailability { ready, processing, unavailable }

enum ModelFileFormat { glb }

enum ModelDetail { standard, high }

/// Host-supplied presentation facts, independent of WebView loading progress.
/// Null statistics mean unknown; rendering success never implies completion.
@immutable
class ModelViewerData {
  const ModelViewerData({
    required this.modelName,
    required this.availability,
    this.referenceCode,
    this.format,
    this.detail,
    this.completionPercentage,
  }) : assert(
         completionPercentage == null ||
             (completionPercentage >= 0 && completionPercentage <= 100),
       );

  final String modelName;
  final String? referenceCode;
  final ModelAvailability availability;
  final ModelFileFormat? format;
  final ModelDetail? detail;
  final int? completionPercentage;
}
