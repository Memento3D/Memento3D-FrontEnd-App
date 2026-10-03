import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import 'capture_session.dart';
import 'model_confirmation_state.dart';
import 'processing_screen.dart';

const _purple = Color(0xFF6B4FE8);
const _purpleDark = Color(0xFF5B3FD6);
const _lavender = Color(0xFFF2EEFF);
const _ink = Color(0xFF29243D);
const _muted = Color(0xFF777183);
const _border = Color(0xFFE6DFFF);

/// "Create 3D Model from Photos — Confirmation" screen.
///
/// Shown right before an image-to-3D request is submitted. It lets the user
/// review the uploaded photos, the generated model configuration and the
/// current processing status before tapping the primary CTA.
class ModelConfirmationScreen extends StatefulWidget {
  const ModelConfirmationScreen({
    super.key,
    required this.session,
    this.onSubmit,
  });

  final CaptureSession session;

  /// Submits the image-to-3D request. Defaults to the existing capture-first
  /// flow via [submitCaptureSession].
  final ModelGenerationSubmitter? onSubmit;

  @override
  State<ModelConfirmationScreen> createState() =>
      _ModelConfirmationScreenState();
}

class _ModelConfirmationScreenState extends State<ModelConfirmationScreen> {
  late ModelConfirmationState _state;

  @override
  void initState() {
    super.initState();
    _state = ModelConfirmationState(session: widget.session);
  }

  @override
  void didUpdateWidget(covariant ModelConfirmationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      _state.dispose();
      _state = ModelConfirmationState(session: widget.session);
    }
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_state.canSubmit) return;
    _state.beginSubmission();

    final strings = AppLocalizations.of(context)!;
    final submitter = widget.onSubmit ?? submitCaptureSession;
    try {
      final snapshot = await submitter(widget.session);
      if (!mounted) return;
      _state.resetSubmission();
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (context) =>
              ProcessingScreen(session: widget.session, snapshot: snapshot),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _state.failSubmission(strings.modelConfirmationError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.modelConfirmationError),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFFCFAFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: _ink),
          tooltip: strings.back,
        ),
        title: Text(
          strings.modelConfirmationTitle,
          style: GoogleFonts.plusJakartaSans(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Tooltip(
            message: strings.modelConfirmationAiTooltip,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _lavender,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: _purple,
                size: 19,
                semanticLabel: 'AI',
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFF1F0F5)),
        ),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
                    children: [
                      _photoPreviewCard(strings),
                      const SizedBox(height: 18),
                      _summaryCard(strings),
                    ],
                  ),
                ),
                _bottomAction(strings),
              ],
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // SECTION A — Photo preview
  // ---------------------------------------------------------------

  Widget _photoPreviewCard(AppLocalizations strings) {
    final photos = widget.session.capturedPhotos;
    final original = photos.isNotEmpty ? photos.first : null;
    final keepsake = photos.length > 1 ? photos.last : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _lavender,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _photoTile(
                  photo: original,
                  label: strings.modelConfirmationOriginalPhoto,
                  unavailableLabel: strings.imageUnavailable,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _aiConnector(),
              ),
              Expanded(
                child: _photoTile(
                  photo: keepsake,
                  label: strings.modelConfirmationKeepsakePhoto,
                  unavailableLabel: strings.imageUnavailable,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _consentBadge(strings),
              const Spacer(),
              const Icon(
                Icons.photo_library_outlined,
                size: 14,
                color: _muted,
                semanticLabel: 'Photos',
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  strings.modelConfirmationAllPhotos,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoTile({
    required XFile? photo,
    required String label,
    required String unavailableLabel,
  }) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 0.86,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              color: Colors.white,
              child: photo == null
                  ? _photoPlaceholder()
                  : _PhotoPreview(
                      photo: photo,
                      unavailableLabel: unavailableLabel,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
      ],
    );
  }

  Widget _photoPlaceholder() {
    return const Center(
      child: Icon(
        Icons.add_photo_alternate_outlined,
        color: _purple,
        size: 26,
        semanticLabel: 'Photo placeholder',
      ),
    );
  }

  Widget _aiConnector() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purple, _purpleDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: Colors.white,
        size: 19,
        semanticLabel: 'AI',
      ),
    );
  }

  Widget _consentBadge(AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 14,
            color: Color(0xFF065F46),
            semanticLabel: 'Consent confirmed',
          ),
          const SizedBox(width: 5),
          Text(
            strings.modelConfirmationConsentBadge,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF065F46),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // SECTIONS B & C — Generation summary, info box and processing rows
  // ---------------------------------------------------------------

  Widget _summaryCard(AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.modelConfirmationHeader,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.modelConfirmationSubtitle(widget.session.photoCount),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _muted,
            ),
          ),
          const SizedBox(height: 14),
          _infoBox(strings),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 6),
          _infoRow(
            icon: Icons.image_outlined,
            title: strings.modelConfirmationUploadedTitle,
            value: strings.modelConfirmationUploadedValue(
              widget.session.photoCount,
            ),
            trailing: Icon(
              Icons.check_circle,
              size: 20,
              color: const Color(0xFF10B981),
              semanticLabel: 'Completed',
            ),
          ),
          const Divider(height: 1, color: _border),
          _infoRow(
            icon: Icons.view_in_ar_outlined,
            title: strings.modelConfirmationGeneratedTitle,
            value: strings.modelConfirmationGeneratedValue,
            trailing: _statusBadge(
              strings.modelConfirmationGenerating,
              const Color(0xFFFFDEC9),
              const Color(0xFFC2410C),
            ),
          ),
          const Divider(height: 1, color: _border),
          _infoRow(
            icon: Icons.description_outlined,
            title: strings.modelConfirmationFormatTitle,
            value: strings.modelConfirmationFormatValue,
            trailing: _statusBadge(
              strings.modelConfirmationFormatBadge,
              const Color(0xFFEDE9FE),
              const Color(0xFF7C3AED),
            ),
          ),
          if (_state.showWarning) ...[
            const SizedBox(height: 14),
            _warningBanner(strings),
          ],
        ],
      ),
    );
  }

  Widget _infoBox(AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _lavender,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 18,
            color: _purple,
            semanticLabel: 'AI',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.modelConfirmationInfo,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4C3E8A),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _lavender,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 19, color: _purple),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }

  Widget _statusBadge(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  Widget _warningBanner(AppLocalizations strings) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: Color(0xFFD97706),
            semanticLabel: 'Warning',
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              strings.modelConfirmationWarning,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Primary CTA
  // ---------------------------------------------------------------

  Widget _bottomAction(AppLocalizations strings) {
    final submitting = _state.isSubmitting;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFFCFAFF),
        border: Border(top: BorderSide(color: Color(0xFFF1F0F5))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_state.errorMessage != null) ...[
            Text(
              _state.errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 8),
          ],
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _state.canSubmit ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _purple.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            strings.modelConfirmationCta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: _muted,
                semanticLabel: 'Estimated time',
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  strings.modelConfirmationEstimate,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Renders an uploaded photo with a graceful fallback for unreadable files.
class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo, required this.unavailableLabel});

  final XFile photo;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    // Temporary preview support: asset paths work on Flutter Web,
    // real captures use Image.file on mobile/desktop.
    if (photo.path.startsWith('assets/')) {
      return Image.asset(
        photo.path,
        fit: BoxFit.cover,
        semanticLabel: unavailableLabel,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }
    return Image.file(
      File(photo.path),
      fit: BoxFit.cover,
      semanticLabel: unavailableLabel,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() => Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            unavailableLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 11),
          ),
        ),
      );
}
