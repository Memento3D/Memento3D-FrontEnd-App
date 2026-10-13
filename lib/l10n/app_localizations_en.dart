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
  String get uploadTitle => 'Uploading photos';

  @override
  String get uploadPreparing => 'Preparing upload';

  @override
  String get uploadUploading => 'Uploading';

  @override
  String get uploadWaiting => 'Waiting for connection';

  @override
  String get uploadReconciling => 'Restoring upload';

  @override
  String get uploadRetryNeeded => 'Retry needed';

  @override
  String get uploadCompleted => 'Photo upload complete';

  @override
  String get uploadMainTitle => 'Uploading your photos';

  @override
  String get uploadNetworkBanner => 'Waiting to reconnect';

  @override
  String get uploadNetworkBody =>
      'Confirmed progress is unchanged. Uploading will continue when the connection returns.';

  @override
  String get uploadReconcilingTitle => 'Restoring your upload session';

  @override
  String get uploadReconcilingBody =>
      'Checking the last confirmed position before continuing. Your progress stays unchanged while we check.';

  @override
  String get uploadCompletionBody => 'Moving to quality check...';

  @override
  String get uploadFailureBody =>
      'Your confirmed progress is unchanged. Try again to continue from the last confirmed position.';

  @override
  String get uploadSourceFailureBody =>
      'Upload updates are unavailable. Your confirmed progress is unchanged; try again to reconnect.';

  @override
  String get uploadLocalPhotos => 'Local photos';

  @override
  String get uploadSavedTitle => 'Progress is saved automatically';

  @override
  String get uploadSavedBody =>
      'You can return to this upload after an interruption. It will continue from the last confirmed position.';

  @override
  String get uploadSessionOnlyTitle => 'Keep this session open';

  @override
  String get uploadSessionOnlyBody =>
      'Confirmed progress remains visible in this session. Recovery after closing the app is not available yet.';

  @override
  String uploadPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String uploadPercent(String value) {
    return '$value%';
  }

  @override
  String uploadSummaryProgress(String value) {
    return '$value% uploaded';
  }

  @override
  String uploadUnitCount(int confirmed, int total) {
    return '$confirmed / $total';
  }

  @override
  String uploadConfirmedParts(int confirmed, int total) {
    return '$confirmed / $total parts uploaded';
  }

  @override
  String get uploadProgressLabel => 'Confirmed upload progress';

  @override
  String get uploadSpeed => 'Speed';

  @override
  String uploadSpeedValue(String value) {
    return '$value MB/s';
  }

  @override
  String get uploadRemaining => 'Remaining';

  @override
  String uploadEtaValue(int minutes, int seconds) {
    return '~${minutes}m ${seconds}s';
  }

  @override
  String get uploadEtaWaiting => 'Waiting';

  @override
  String get uploadUnknownMetric => '—';

  @override
  String get uploadConfirmed => 'Uploaded';

  @override
  String get uploadPhotosTitle => 'Photos in this upload';

  @override
  String get uploadPhotoCompleted => 'Uploaded';

  @override
  String get uploadPhotoCurrent => 'Uploading';

  @override
  String get uploadPhotoPending => 'Pending';

  @override
  String get uploadPhotoPaused => 'Paused';

  @override
  String uploadPhotoDescription(String photo, String status) {
    return '$photo. $status';
  }

  @override
  String get uploadNextSteps => 'Next steps';

  @override
  String get uploadCloudStep => 'Upload to the cloud';

  @override
  String uploadStepProgress(String status, int confirmed, int total) {
    return '$status ($confirmed/$total parts)';
  }

  @override
  String get uploadQualityStep => 'Quality check & preparation';

  @override
  String get uploadQualityNextBody => 'The next step after upload';

  @override
  String get uploadNext => 'Next';

  @override
  String get photoUploadComplete =>
      'All photos have confirmed upload results. You can return to capture.';

  @override
  String get photoUploadRetrying => 'Retrying the photo that was not submitted';

  @override
  String get photoUploadConfirm => 'Upload photos';

  @override
  String get photoUploadStopped => 'Upload stopped';

  @override
  String get photoUploadAmbiguous =>
      'The upload result for the current photo could not be confirmed. It may already exist on the server. Upload stopped; this photo will not be sent again.';

  @override
  String get photoUploadRejected =>
      'The server rejected this photo. Upload stopped. Previously confirmed photos are retained.';

  @override
  String get photoUploadNotSubmitted =>
      'This photo was not submitted. Check the local file, then retry explicitly.';

  @override
  String photoUploadConfirmed(int confirmed, int total) {
    return '$confirmed / $total photos confirmed';
  }
}
