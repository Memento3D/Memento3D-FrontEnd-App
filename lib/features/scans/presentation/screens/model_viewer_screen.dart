import 'package:flutter/material.dart';

import '../../../model_viewer/presentation/screens/model_viewer_screen.dart'
    as viewer;
import '../../data/models/scan_item.dart';

/// Compatibility entry point for the API-backed GLB viewer.
class ModelViewerScreen extends StatelessWidget {
  const ModelViewerScreen({super.key, required this.scanId, this.scan});

  final String scanId;
  final ScanItem? scan;

  @override
  Widget build(BuildContext context) =>
      viewer.ModelViewerScreen(scanId: scanId, scanName: scan?.name);
}
