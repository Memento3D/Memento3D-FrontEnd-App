import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'capture_session.dart';

const _purple = Color(0xFF6B4FE8);
const _lavender = Color(0xFFF2EEFF);
const _ink = Color(0xFF29243D);
const _border = Color(0xFFE6DFFF);

class CaptureReviewScreen extends StatefulWidget {
  const CaptureReviewScreen({super.key, required this.session});

  final CaptureSession session;

  @override
  State<CaptureReviewScreen> createState() => _CaptureReviewScreenState();
}

class _CaptureReviewScreenState extends State<CaptureReviewScreen> {
  late Future<CaptureSizeSummary> _sizeFuture;
  XFile? _selectedPhoto;

  @override
  void initState() {
    super.initState();
    _selectedPhoto = widget.session.latestPhoto;
    _sizeFuture = widget.session.measureSize();
  }

  void _removePhoto(XFile photo) {
    setState(() {
      widget.session.removePhoto(photo);
      if (_selectedPhoto == photo) {
        _selectedPhoto = widget.session.latestPhoto;
      }
      _sizeFuture = widget.session.measureSize();
    });
  }

  void _openPhoto(XFile photo) {
    setState(() => _selectedPhoto = photo);
    final strings = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFCFAFF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                child: Row(
                  children: [
                    Text(
                      strings.photoNumber(
                        widget.session.capturedPhotos.indexOf(photo) + 1,
                      ),
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                      tooltip: strings.closePreview,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: ColoredBox(
                      color: _lavender,
                      child: InteractiveViewer(
                        child: Center(
                          child: _PhotoImage(
                            photo: photo,
                            unavailableLabel: strings.imageUnavailable,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _removePhoto(photo);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(strings.deletePhoto),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: Text(strings.retakePhoto),
                        style: FilledButton.styleFrom(backgroundColor: _purple),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatSize(AppLocalizations strings, int bytes) {
    const bytesPerKilobyte = 1024;
    const bytesPerMegabyte = bytesPerKilobyte * bytesPerKilobyte;
    if (bytes >= bytesPerMegabyte) {
      return strings.fileSizeMb((bytes / bytesPerMegabyte).toStringAsFixed(1));
    }
    return strings.fileSizeKb((bytes / bytesPerKilobyte).toStringAsFixed(1));
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    final photos = widget.session.capturedPhotos;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 58,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: _ink),
                            tooltip: strings.back,
                          ),
                          Text(
                            strings.reviewTitle,
                            style: const TextStyle(
                              color: _ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 19,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_vert, color: _ink),
                            tooltip: strings.moreOptions,
                          ),
                          const SizedBox(width: 6),
                          Tooltip(
                            message: strings.profile,
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: _purple,
                              child: Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      strings.captureSessionTitle,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _summaryCard(strings),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          strings.capturedPhotoSection,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _lavender,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            '${photos.length}',
                            style: const TextStyle(
                              color: _purple,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.crossAxisExtent;
                  final columns = width < 340 ? 2 : 3;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.88,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index < photos.length) {
                        final photo = photos[index];
                        return _photoTile(photo, index, strings);
                      }
                      if (index == photos.length) return _addTile(strings);
                      return _unavailableTile(strings);
                    }, childCount: photos.length + 2),
                  );
                },
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          strings.detailTitle,
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            strings.detailSubtitle,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: Color(0xFF777183),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _detailOption(
                      strings.detailStandard,
                      strings.detailStandardDescription,
                      ReconstructionDetailLevel.standard,
                    ),
                    const SizedBox(height: 10),
                    _detailOption(
                      strings.detailHigh,
                      strings.detailHighDescription,
                      ReconstructionDetailLevel.highDetail,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.detailSelectionOnly,
                      style: const TextStyle(
                        color: Color(0xFF777183),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _summaryValue(
                '${widget.session.photoCount}',
                strings.sessionPhotoCount,
                _purple,
              ),
              Container(width: 1, height: 45, color: _border),
              FutureBuilder<CaptureSizeSummary>(
                future: _sizeFuture,
                builder: (context, snapshot) {
                  final summary = snapshot.data;
                  return _summaryValue(
                    summary == null
                        ? strings.sizeCalculating
                        : _formatSize(strings, summary.bytes),
                    strings.sessionFileSize,
                    _ink,
                  );
                },
              ),
              Container(width: 1, height: 45, color: _border),
              _summaryValue(
                strings.metricUnavailable,
                strings.sessionQuality,
                const Color(0xFF777183),
              ),
            ],
          ),
          FutureBuilder<CaptureSizeSummary>(
            future: _sizeFuture,
            builder: (context, snapshot) {
              if ((snapshot.data?.unavailableFiles ?? 0) == 0) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  strings.sizeIncomplete,
                  style: const TextStyle(
                    color: Color(0xFF9A5760),
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryValue(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: _ink),
          ),
        ],
      ),
    );
  }

  Widget _photoTile(XFile photo, int index, AppLocalizations strings) {
    final selected = _selectedPhoto == photo;
    return InkWell(
      onTap: () => _openPhoto(photo),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _lavender,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? _purple : _border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _PhotoImage(
              photo: photo,
              unavailableLabel: strings.imageUnavailable,
              fit: BoxFit.cover,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                color: Colors.black54,
                child: Text(
                  strings.photoNumber(index + 1),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addTile(AppLocalizations strings) {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: _purple, style: BorderStyle.solid),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.all(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_a_photo_outlined, color: _purple),
          const SizedBox(height: 6),
          Text(
            strings.addAngle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            strings.addAngleHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF777183), fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _unavailableTile(AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.view_in_ar_outlined, color: _purple),
          const SizedBox(height: 6),
          Text(
            strings.modelPreviewUnavailable,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _detailOption(
    String label,
    String description,
    ReconstructionDetailLevel level,
  ) {
    final selected = widget.session.detailLevel == level;
    return InkWell(
      onTap: () => setState(() => widget.session.detailLevel = level),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _purple : _border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: _purple,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? _purple : _ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xFF777183),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  const _PhotoImage({
    required this.photo,
    required this.unavailableLabel,
    required this.fit,
  });
  final XFile photo;
  final String unavailableLabel;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(photo.path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            unavailableLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ink, fontSize: 11),
          ),
        ),
      ),
    );
  }
}
