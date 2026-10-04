// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get captureTitle => 'Capture';

  @override
  String get back => 'Back';

  @override
  String get moreOptions => 'More options';

  @override
  String get profile => 'Profile';

  @override
  String get moveSlowly => '✨ Move slowly around the object 🌸';

  @override
  String get keepStill =>
      'Keep the object still and maintain a steady distance.';

  @override
  String capturedPhotos(int count) {
    return '$count photos captured';
  }

  @override
  String get orbitLabel => '360° Orbit';

  @override
  String get distanceGood => 'Distance good';

  @override
  String get balanceGood => 'Balanced';

  @override
  String get naturalLight => 'Natural light';

  @override
  String get grid => 'Grid';

  @override
  String get photo => 'Photo';

  @override
  String get video => 'Video';

  @override
  String get preview => 'Preview';

  @override
  String get done => 'Done';

  @override
  String get nextStep => 'Next step';

  @override
  String get restorationTitle => 'Wabi-Sabi restoration';

  @override
  String get restorationBody =>
      'Preserve every detail of your object\'s story.';

  @override
  String get automatic => 'Automatic';

  @override
  String get cameraUnavailable => 'No camera found on this device.';

  @override
  String get cameraError => 'Could not open camera.';

  @override
  String get captureError => 'Could not capture photo.';

  @override
  String get retry => 'Retry';

  @override
  String get capturePhoto => 'Capture photo';

  @override
  String get photoCaptured => 'Photo captured';

  @override
  String get wizardReadyTitle => 'Move slowly around the object';

  @override
  String get wizardReadyBody =>
      'Keep the object still and maintain a stable distance.';

  @override
  String get wizardTiltedTitle => 'Keep your phone straight';

  @override
  String get wizardTiltedBody =>
      'Adjust the phone orientation before continuing.';

  @override
  String get wizardMovingTitle => 'Move more slowly';

  @override
  String get wizardMovingBody => 'Slow movement helps capture clearer views.';

  @override
  String get wizardCapturedTitle => 'Photo captured';

  @override
  String get wizardCapturedBody => 'Continue moving around the object.';

  @override
  String get reviewTitle => 'Review';

  @override
  String get captureSessionTitle => 'Object capture session';

  @override
  String get sessionPhotoCount => 'Photos';

  @override
  String get sessionFileSize => 'File size';

  @override
  String get sessionQuality => '3D quality';

  @override
  String get metricUnavailable => 'Unavailable';

  @override
  String get sizeCalculating => 'Calculating';

  @override
  String get sizeIncomplete => 'Some files unavailable';

  @override
  String fileSizeKb(String value) {
    return '$value KB';
  }

  @override
  String fileSizeMb(String value) {
    return '$value MB';
  }

  @override
  String get capturedPhotoSection => 'Captured photos';

  @override
  String get addAngle => 'Add angle';

  @override
  String get addAngleHint => 'Capture another view';

  @override
  String photoNumber(int number) {
    return 'Photo $number';
  }

  @override
  String get imageUnavailable => 'Image unavailable';

  @override
  String get deletePhoto => 'Remove photo';

  @override
  String get retakePhoto => 'Retake';

  @override
  String get closePreview => 'Close preview';

  @override
  String get detailTitle => 'Detail level';

  @override
  String get detailSubtitle => 'For future 3D reconstruction';

  @override
  String get detailStandard => 'Standard';

  @override
  String get detailStandardDescription =>
      'Suitable for quick web and mobile previews.';

  @override
  String get detailHigh => 'High detail';

  @override
  String get detailHighDescription =>
      'Preserve more surface detail for a future 3D model.';

  @override
  String get detailSelectionOnly =>
      'Selection only — reconstruction is not available yet.';

  @override
  String get modelPreviewUnavailable => '3D preview unavailable';

  @override
  String get processingCta => 'View processing status';

  @override
  String get processingTitle => 'Processing';

  @override
  String get processingLocal => 'Local capture session';

  @override
  String get processingCloudUnavailable => 'Cloud service not connected';

  @override
  String processingPhotoCount(int count) {
    return '$count photos captured';
  }

  @override
  String get processingReadyTitle => 'Ready to upload';

  @override
  String get processingReadyBody =>
      'Your photos are prepared locally. Processing will be available when a service is connected.';

  @override
  String get processingWaiting => 'Waiting for processing service';

  @override
  String get processingProgressPending =>
      'Progress will appear here when processing starts.';

  @override
  String get processingStageTitle => 'Processing stages';

  @override
  String get processingStagePending => 'Pending';

  @override
  String get processingStageActive => 'In progress';

  @override
  String get processingStageCompleted => 'Completed';

  @override
  String get processingStageUpload => 'Data upload';

  @override
  String get processingStagePrepare => 'Image preparation';

  @override
  String get processingStageStructure => '3D structure reconstruction';

  @override
  String get processingStageDetail => 'Detail generation';

  @override
  String get processingStageTexture => 'Texturing and finalization';

  @override
  String get processingStageComplete => 'Completion';

  @override
  String get processingSelectedDetail => 'Selected detail';

  @override
  String get processingFileSize => 'Local file size';

  @override
  String get processingMissingImage => 'Captured image unavailable';

  @override
  String get processingNotStarted => 'No upload or reconstruction has started.';

  @override
  String get processingUploading => 'Uploading photos';

  @override
  String get processingRunning => 'Processing photos';

  @override
  String get processingCompleted => 'Processing completed';

  @override
  String get processingFailed => 'Processing failed';

  @override
  String get processingCloudConnected => 'Processing service connected';

  @override
  String get processingInProgressBody =>
      'Progress is based on service updates.';

  @override
  String get processingCompleteBody =>
      'The processing service reports completion.';

  @override
  String get processingFailedBody =>
      'The processing service reported a problem.';

  @override
  String get qualityRiskTitle => 'Confirm risks';

  @override
  String get qualityNeedsConfirmation => 'CONFIRMATION NEEDED';

  @override
  String get qualityHeroTitle => 'Image quality is not fully optimal';

  @override
  String get qualityHeroBody =>
      'Reconstruction is still possible, but some images may affect the accuracy of your 3D model.';

  @override
  String get qualitySummaryTitle => 'Image quality summary';

  @override
  String get qualityQualified => 'Qualified';

  @override
  String get qualityNeedsAttention => 'Needs attention';

  @override
  String get qualityOverallScore => 'Overall quality';

  @override
  String qualityPercentage(String value) {
    return '$value%';
  }

  @override
  String qualityReviewImages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count images need review',
      one: '1 image needs review',
      zero: 'Review quality warnings',
    );
    return '$_temp0';
  }

  @override
  String get qualityViewDetails => 'View warnings and potential impact';

  @override
  String get qualityRiskDetailsTitle => 'Check before continuing';

  @override
  String qualityRiskDetailsSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Review the possible impact of $count images before deciding.',
      one: 'Review the possible impact of 1 image before deciding.',
      zero: 'Review the quality warnings before deciding.',
    );
    return '$_temp0';
  }

  @override
  String get qualityAffectedImages => 'Images needing attention';

  @override
  String qualityAdditionalAffectedImages(int count) {
    return '$count additional images need attention';
  }

  @override
  String get qualityNoAffectedImages => 'No affected images to preview.';

  @override
  String get qualityImpactTitle => 'What could this affect?';

  @override
  String get qualitySurfaceRisk =>
      'Surface details may be less sharp in some areas.';

  @override
  String get qualityGeometryRisk =>
      'Geometry may be slightly less accurate in poorly captured areas.';

  @override
  String get qualityReassurance =>
      'You can continue with these images, or go back to improve the capture for potentially better results.';

  @override
  String get qualityAcknowledgement =>
      'I understand the risks and still want to continue';

  @override
  String get qualityAcknowledgementHint =>
      'Quality warnings may affect the final 3D result. Confirm only when you are ready to accept these risks.';

  @override
  String get qualityCloseDetails => 'Close risk details';

  @override
  String get qualityContextChanged =>
      'The quality report changed. Close this sheet and review the current report.';

  @override
  String get qualityContinue => 'Confirm and continue';

  @override
  String get qualitySubmitting => 'Confirming…';

  @override
  String get qualityBackToImages => 'Go back to review images';

  @override
  String get qualityBackToReport => 'Go back to the quality report';

  @override
  String get qualityBlockedStatus => 'UNABLE TO CONTINUE';

  @override
  String get qualityRejectedTitle => 'Cannot continue with these images';

  @override
  String get qualityRejectedBody =>
      'The current image quality is not suitable for continuing. Please go back to review your images.';

  @override
  String get qualityIneligibleStatus => 'REVIEW REQUIRED';

  @override
  String get qualityIneligibleTitle => 'Please return to the quality report';

  @override
  String get qualityIneligibleBody =>
      'Risk confirmation is not available for this report. Go back to review the current image quality.';

  @override
  String get qualityRecoverableFailure =>
      'We could not confirm your request. Your acknowledgement is saved; please try again.';

  @override
  String get qualityRetry => 'Try confirmation again';

  @override
  String get qualityConfirmedStatus => 'CONFIRMED';

  @override
  String get qualityConfirmedTitle => 'Risks confirmed';

  @override
  String get qualityConfirmedBody => 'Your confirmation has been accepted.';
}
