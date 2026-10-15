import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../features/orders/presentation/screens/print_order_config_screen.dart';
import '../../../../screens/printability_report_screen.dart';
import '../../../../screens/rate_share_screen.dart';
import '../../data/services/model_download_service.dart';
import '../../data/services/model_output_service.dart';
import '../models/model_viewer_data.dart';
import '../widgets/three_d_model_viewer.dart';

const _primary = Color(0xFF5B3CDD);
const _success = Color(0xFF006A3B);

/// Host-owned facts and navigation around the reusable real Three.js viewer.
class ModelViewerScreen extends StatefulWidget {
  const ModelViewerScreen({
    super.key,
    this.modelUrl,
    this.data,
    this.onContinue,
    this.onBack,
    this.onMenu,
    this.onProfile,
    this.enableDiagnostics = false,
    this.scanId,
    this.scanName,
    this.onCheckPrintability,
    this.onRateShare,
    this.onOrderPrint,
    this.modelOutputService,
    this.modelDownloadService,
  }) : assert(
         scanId != null || (modelUrl != null && data != null),
         'Provide either scanId (real data flow) or modelUrl/data.',
       );

  final String? modelUrl;
  final ModelViewerData? data;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;
  final VoidCallback? onProfile;

  /// Development-only opt-in; leaves the production composition unchanged.
  final bool enableDiagnostics;

  /// Production flow: fetch the primary GLB from model_outputs and viewer it.
  final String? scanId;
  final String? scanName;
  final VoidCallback? onCheckPrintability;
  final VoidCallback? onRateShare;
  final VoidCallback? onOrderPrint;
  final ModelOutputService? modelOutputService;
  final ModelDownloadService? modelDownloadService;

  @override
  State<ModelViewerScreen> createState() => _ModelViewerScreenState();
}

enum _FlowPhase { fetching, downloading, ready, unavailable, error }

class _ModelViewerScreenState extends State<ModelViewerScreen> {
  late final ModelOutputService _outputs =
      widget.modelOutputService ?? ModelOutputService();
  late final ModelDownloadService _downloads =
      widget.modelDownloadService ?? ModelDownloadService();

  _FlowPhase _phase = _FlowPhase.fetching;
  int _loadedBytes = 0;
  int? _totalBytes;
  String? _modelUrl;
  ModelViewerData? _data;

  @override
  void initState() {
    super.initState();
    if (widget.scanId != null) {
      _loadRealModel();
    }
  }

  Future<void> _loadRealModel() async {
    setState(() {
      _phase = _FlowPhase.fetching;
      _loadedBytes = 0;
      _totalBytes = null;
    });
    try {
      final output = await _outputs.getPrimaryGlbOutput(widget.scanId!);
      if (!mounted) return;
      if (output == null || output.downloadUrl == null) {
        setState(() => _phase = _FlowPhase.unavailable);
        return;
      }
      setState(() => _phase = _FlowPhase.downloading);
      final file = await _downloads.downloadGlb(
        url: output.downloadUrl!,
        onProgress: (loaded, total) {
          if (!mounted) return;
          setState(() {
            _loadedBytes = loaded;
            _totalBytes = total;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _modelUrl = 'file://${file.path}';
        _data = ModelViewerData(
          modelName: widget.scanName ?? output.id,
          referenceCode: widget.scanId,
          availability: ModelAvailability.ready,
          format: ModelFileFormat.glb,
          completionPercentage: 100,
        );
        _phase = _FlowPhase.ready;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _FlowPhase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inherited = Theme.of(context);
    final colors = ColorScheme.fromSeed(seedColor: _primary).copyWith(
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF7459F7),
      onPrimaryContainer: Colors.white,
      primaryFixed: const Color(0xFFE5DEFF),
      surface: const Color(0xFFFDF8FF),
      surfaceContainer: const Color(0xFFF1EBFF),
      surfaceContainerLow: const Color(0xFFF7F1FF),
      onSurface: const Color(0xFF1C1831),
      onSurfaceVariant: const Color(0xFF484555),
      outlineVariant: const Color(0xFFE5DEFF),
    );
    final theme = inherited.copyWith(
      colorScheme: colors,
      scaffoldBackgroundColor: const Color(0xFFFBF8FF),
      textTheme: inherited.textTheme.apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
      ),
    );
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          if (widget.scanId != null && _phase != _FlowPhase.ready) {
            return _buildFlowScreen(context);
          }
          return _buildScreen(
            context,
            modelUrl: _modelUrl ?? widget.modelUrl,
            data: _data ?? widget.data!,
          );
        },
      ),
    );
  }

  /// Loading / ready / error indicators for the real data pipeline.
  Widget _buildFlowScreen(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Text(
          strings.modelViewerScreenTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (_phase) {
              _FlowPhase.fetching => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(strings.modelViewerFetchingOutputs),
                ],
              ),
              _FlowPhase.downloading => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(
                    value: _totalBytes == null || _totalBytes == 0
                        ? null
                        : (_loadedBytes / _totalBytes!).clamp(0.0, 1.0),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _totalBytes == null || _totalBytes == 0
                        ? strings.modelViewerDownloading
                        : '${strings.modelViewerDownloading} ${((_loadedBytes / _totalBytes!) * 100).round()}%',
                  ),
                ],
              ),
              _FlowPhase.unavailable => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.modelViewerNoPrimaryGlb,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              _FlowPhase.error => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.modelViewerLoadError,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadRealModel,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(strings.modelViewerRetry),
                  ),
                ],
              ),
              _FlowPhase.ready => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(
    BuildContext context, {
    required String? modelUrl,
    required ModelViewerData data,
  }) {
    final strings = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final ready = data.availability == ModelAvailability.ready;
    final status = switch (data.availability) {
      ModelAvailability.ready => strings.modelViewerModelReady,
      ModelAvailability.processing => strings.processingRunning,
      ModelAvailability.unavailable => strings.modelPreviewUnavailable,
    };
    final explanation = switch (data.availability) {
      ModelAvailability.ready => strings.modelViewerReadyExplanation,
      ModelAvailability.processing => strings.modelViewerPendingExplanation,
      ModelAvailability.unavailable =>
        strings.modelViewerUnavailableExplanation,
    };
    final statusIcon = switch (data.availability) {
      ModelAvailability.ready => Icons.check_circle_outline_rounded,
      ModelAvailability.processing => Icons.hourglass_top_rounded,
      ModelAvailability.unavailable => Icons.info_outline_rounded,
    };
    final badge = Container(
      key: const ValueKey('model-viewer-ready-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: ready ? const Color(0xFFE4F5EB) : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: ready ? _success : colors.primary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              status,
              style: theme.textTheme.labelSmall?.copyWith(
                color: ready ? _success : colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.modelName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (data.referenceCode != null) ...[
          const SizedBox(height: 6),
          Text(
            strings.modelViewerReference(data.referenceCode!),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                strings.modelViewerScreenTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: strings.moreOptions,
            onPressed: widget.onMenu,
            icon: const Icon(Icons.more_horiz),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              tooltip: strings.profile,
              onPressed: widget.onProfile,
              style: IconButton.styleFrom(backgroundColor: colors.primaryFixed),
              icon: const Icon(Icons.person_outline, color: _primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('model-viewer-scroll'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final largeText =
                      MediaQuery.textScalerOf(context).scale(14) > 21;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (constraints.maxWidth < 320 || largeText)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            identity,
                            const SizedBox(height: 10),
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: badge,
                            ),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: identity),
                            const SizedBox(width: 12),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: constraints.maxWidth * .42,
                              ),
                              child: badge,
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      _Surface(
                        child: ThreeDModelViewer(
                          modelUrl: modelUrl,
                          enableDiagnostics: widget.enableDiagnostics,
                          viewportHeight: largeText ? 440 : 350,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _Surface(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colors.primaryFixed,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      statusIcon,
                                      color: colors.primary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          status,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          explanation,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: colors.onSurfaceVariant,
                                                height: 1.6,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Divider(color: colors.outlineVariant, height: 1),
                              const SizedBox(height: 20),
                              LayoutBuilder(
                                builder: (context, statsConstraints) {
                                  final columns =
                                      statsConstraints.maxWidth >= 300 &&
                                          !largeText
                                      ? 3
                                      : 1;
                                  final width =
                                      (statsConstraints.maxWidth -
                                          (columns - 1) * 12) /
                                      columns;
                                  return Wrap(
                                    spacing: 12,
                                    runSpacing: 16,
                                    children: [
                                      _Statistic(
                                        width: width,
                                        label: strings.modelViewerFormat
                                            .toUpperCase(),
                                        value:
                                            data.format == ModelFileFormat.glb
                                            ? strings.modelViewerFormatGlb
                                            : strings.metricUnavailable,
                                      ),
                                      _Statistic(
                                        width: width,
                                        label: strings.modelViewerDetail
                                            .toUpperCase(),
                                        value: switch (data.detail) {
                                          ModelDetail.standard =>
                                            strings.detailStandard,
                                          ModelDetail.high =>
                                            strings.modelViewerDetailHigh,
                                          null => strings.metricUnavailable,
                                        },
                                      ),
                                      _Statistic(
                                        width: width,
                                        label: strings.modelViewerStatus
                                            .toUpperCase(),
                                        value: data.completionPercentage == null
                                            ? strings.metricUnavailable
                                            : strings.modelViewerPercentage(
                                                data.completionPercentage!,
                                              ),
                                        success: ready,
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (widget.scanId != null) ...[
                        FilledButton(
                          key: const ValueKey(
                            'model-viewer-check-printability',
                          ),
                          onPressed:
                              widget.onCheckPrintability ??
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PrintabilityReportScreen(
                                    scanId: widget.scanId!,
                                    scanName: widget.scanName,
                                  ),
                                ),
                              ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.print_outlined, size: 20),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  strings.checkPrintabilityCta,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          key: const ValueKey('model-viewer-order-print'),
                          onPressed:
                              widget.onOrderPrint ??
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PrintOrderConfigScreen(
                                    scanId: widget.scanId!,
                                    scanName: widget.scanName,
                                  ),
                                ),
                              ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.shopping_bag_outlined, size: 20),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  strings.orderPhysicalPrintCta,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          key: const ValueKey('model-viewer-rate-share'),
                          onPressed:
                              widget.onRateShare ??
                              () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RateShareScreen(
                                    scanId: widget.scanId!,
                                    scanName: widget.scanName,
                                  ),
                                ),
                              ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.share_outlined, size: 20),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  strings.rateAndShareCta,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: widget.onContinue == null
                                ? null
                                : const LinearGradient(
                                    colors: [_primary, Color(0xFF7459F7)],
                                  ),
                            color: widget.onContinue == null
                                ? colors.surfaceContainer
                                : null,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: widget.onContinue == null
                                ? null
                                : [
                                    BoxShadow(
                                      color: _primary.withValues(alpha: .18),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: FilledButton(
                            key: const ValueKey('model-viewer-continue'),
                            onPressed: widget.onContinue,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              disabledBackgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    strings.modelViewerContinue,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [
        BoxShadow(
          color: Color(0x085B3CDD),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _Statistic extends StatelessWidget {
  const _Statistic({
    required this.width,
    required this.label,
    required this.value,
    this.success = false,
  });
  final double width;
  final String label;
  final String value;
  final bool success;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (success) ...[
              const Icon(Icons.check_circle, color: _success, size: 14),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: success ? _success : null,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
