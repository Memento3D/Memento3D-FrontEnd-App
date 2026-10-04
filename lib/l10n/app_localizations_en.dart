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
  String get processingProgressTitle => 'Creating 3D model...';

  @override
  String get processingProgressSubtitle =>
      'AI is analyzing angles and details to build a vivid 3D model.';

  @override
  String get processingProgressLabel => 'PROGRESS';

  @override
  String get processingHistoryTitle => 'PROCESSING LOG';

  @override
  String get processingTipTitle => 'Tip from Memento3D';

  @override
  String get processingTipBody =>
      'Capture extra angles to make the 3D model more accurate.';

  @override
  String get processingRunInBackground => 'Run in background & Get notified';

  @override
  String get processingBackgroundAck =>
      'You will be notified when processing completes.';

  @override
  String get processingReconnecting => 'Reconnecting...';

  @override
  String get processingEtaUnknown => 'Estimating remaining time...';

  @override
  String get processingEtaShort => 'almost done';

  @override
  String processingEtaMinutes(int minutes) {
    return 'about $minutes minutes left';
  }

  @override
  String get jobStageQueued => 'Queued';

  @override
  String get jobStageDownloading => 'Downloading input image';

  @override
  String get jobStagePreprocessing => 'Preprocessing';

  @override
  String get jobStageShapeGeneration => 'Generating 3D shape';

  @override
  String get jobStageTexturing => 'Texturing';

  @override
  String get jobStageValidating => 'Validating';

  @override
  String get jobStageExporting => 'Exporting';

  @override
  String get jobStageUploading => 'Uploading model';

  @override
  String get jobStageDone => 'Done';

  @override
  String processingPhaseStep(int step, int total, String label) {
    return 'Step $step/$total: $label';
  }

  @override
  String get processingPhaseAnalyzing => 'Analyzing input image';

  @override
  String get processingPhaseModeling => 'Building shape & mesh';

  @override
  String get processingPhaseFinishing => 'Texturing & finalizing model';
}
