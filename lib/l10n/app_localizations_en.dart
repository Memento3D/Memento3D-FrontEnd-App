// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get resetPasswordInvalidTitle => 'Link expired';

  @override
  String get resetPasswordInvalidBody =>
      'This password reset link cannot be used. Request a new link to continue.';

  @override
  String get resetPasswordRequestNewLink => 'Request a new link';

  @override
  String get resetPasswordBackToLogin => 'Back to login';

  @override
  String get resetPasswordSuccessTitle => 'Password reset successful';

  @override
  String get resetPasswordSuccessBody =>
      'Your password has been reset. Log in with your new password.';

  @override
  String get resetPasswordHeader => 'Reset password';

  @override
  String get resetPasswordTitle => 'Create a new password';

  @override
  String get resetPasswordSupport => 'Create a new password for your account.';

  @override
  String get resetPasswordNewPassword => 'New password';

  @override
  String get resetPasswordConfirmPassword => 'Confirm password';

  @override
  String get resetPasswordShowPassword => 'Show password';

  @override
  String get resetPasswordHidePassword => 'Hide password';

  @override
  String get resetPasswordNewRequired => 'Please enter a new password.';

  @override
  String get resetPasswordConfirmRequired => 'Please confirm your password.';

  @override
  String get resetPasswordMismatch =>
      'The confirmation password does not match.';

  @override
  String get resetPasswordSubmit => 'Reset password';

  @override
  String get resetPasswordSubmitting => 'Resetting password…';

  @override
  String get resetPasswordTechnicalFailure =>
      'Unable to reset your password right now. Please try again.';

  @override
  String get resetPasswordRetry => 'Try again';

  @override
  String get resetPasswordCancel => 'Cancel';

  @override
  String get forgotPasswordSubmitting => 'Sending request…';

  @override
  String get forgotPasswordSentTitle => 'Check your email';

  @override
  String get forgotPasswordSentBody =>
      'If the email exists, you will receive instructions to reset your password.';

  @override
  String get forgotPasswordSentSupport =>
      'Please check your inbox and follow the link in the email to continue.';

  @override
  String get forgotPasswordGuidanceTitle => 'No email yet?';

  @override
  String get forgotPasswordSpamGuidance => 'Check your Spam / Junk folder.';

  @override
  String get forgotPasswordDeliveryGuidance =>
      'Delivery may take a few minutes.';

  @override
  String get forgotPasswordResend => 'Resend instructions';

  @override
  String get forgotPasswordResending => 'Resending instructions…';

  @override
  String get forgotPasswordTechnicalFailure =>
      'Unable to send the request right now. Please try again.';

  @override
  String get forgotPasswordRetry => 'Try again';

  @override
  String get forgotPasswordHeader => 'Forgot password';

  @override
  String get forgotPasswordTitle => 'Forgot password?';

  @override
  String get forgotPasswordSubtitle =>
      'Don\'t worry, we\'ll help you regain access.';

  @override
  String get forgotPasswordEmailLabel => 'Email';

  @override
  String get forgotPasswordEmailHint => 'Enter your email address';

  @override
  String get forgotPasswordEmailHelper =>
      'Enter the email you used to create your account.';

  @override
  String get forgotPasswordSubmit => 'Send reset instructions';

  @override
  String get forgotPasswordCancel => 'Cancel';

  @override
  String get forgotPasswordBackToLogin => 'Back to login';

  @override
  String get forgotPasswordEmailRequired => 'Please enter your email address.';

  @override
  String get emailVerificationAddressHint =>
      'Check that the email address above is correct.';

  @override
  String get emailVerificationDeliveryHint =>
      'Email delivery may take a little time.';

  @override
  String get emailVerificationVerifyingHint =>
      'Please wait while your verification link is checked.';

  @override
  String get emailVerificationTitle => 'Verify email';

  @override
  String get emailVerificationHeading => 'Check your email';

  @override
  String get emailVerificationSentBody =>
      'A verification link has been sent to:';

  @override
  String get emailVerificationInstruction =>
      'Open the verification link in your email to confirm your address.';

  @override
  String get emailVerificationWaiting => 'Waiting for verification…';

  @override
  String get emailVerificationWaitingBody =>
      'Follow the email link to verify your address. You can continue once verification is confirmed.';

  @override
  String get emailVerificationResendTitle => 'Can\'t find the email?';

  @override
  String get emailVerificationSpamHint =>
      'Check your Spam or Junk folder, or request another verification email.';

  @override
  String get emailVerificationResend => 'Resend verification email';

  @override
  String get emailVerificationSending => 'Sending…';

  @override
  String get emailVerificationResendSuccess =>
      'A new verification email has been sent. Check your inbox.';

  @override
  String get emailVerificationResendFailure =>
      'We couldn\'t send the email. Please try again.';

  @override
  String emailVerificationRetryAfter(int seconds) {
    return 'Resend in $seconds seconds';
  }

  @override
  String get emailVerificationVerifying => 'Verifying your email…';

  @override
  String get emailVerificationVerifyingBody =>
      'Please wait while we check your verification link.';

  @override
  String get emailVerificationSuccessTitle => 'Email verified!';

  @override
  String get emailVerificationSuccessBody =>
      'Your email address has been confirmed. You can continue to the next step.';

  @override
  String get emailVerificationContinue => 'Continue';

  @override
  String get emailVerificationInvalidTitle => 'This link is no longer valid';

  @override
  String get emailVerificationInvalidBody =>
      'The verification link may have expired or be invalid. Request a new email to try again.';

  @override
  String get emailVerificationResendNew => 'Send a new verification email';

  @override
  String get emailVerificationFailure =>
      'We couldn\'t check your link. Please try again when your connection is available.';

  @override
  String get emailVerificationUnknownEmail =>
      'The email address is unavailable. Return to registration to request another verification email.';

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
  String get captureLibrary => 'Library';

  @override
  String get captureCollection => 'Collection';

  @override
  String get capturePrints => 'Prints';

  @override
  String get captureStudio => 'Creation Studio';

  @override
  String get captureSettings => 'Settings';

  @override
  String get captureCamera => 'Camera';

  @override
  String get recordVideo => 'Record video';

  @override
  String get stopVideo => 'Stop recording';

  @override
  String get videoStartError => 'Video recording could not start. Try again.';

  @override
  String get videoFinalizeError =>
      'Video could not be finalized. Try recording again.';

  @override
  String get recordedVideo => 'Recorded video';

  @override
  String get videoUnavailable => 'Video unavailable';

  @override
  String get videoFileChanged =>
      'File has changed since recording. Size shown is from finalization.';

  @override
  String get videoPreviewTitle => 'Video preview';

  @override
  String get videoFinalizedSize => 'Size at capture';

  @override
  String get videoNotSelected => 'No video selected';

  @override
  String get videoLoading => 'Loading video...';

  @override
  String get videoPlay => 'Play';

  @override
  String get videoPause => 'Pause';

  @override
  String videoDuration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String videoTooShort(int seconds) {
    return 'Video must be at least $seconds seconds long.';
  }

  @override
  String get videoDurationSatisfied => 'Minimum duration met.';

  @override
  String get videoPlaybackError =>
      'This video couldn’t be played. Try recording another video.';

  @override
  String get importedVideo => 'Imported video';

  @override
  String get videoReplaceFromLibrary => 'Replace from library';

  @override
  String get videoImportFormatError => 'Select an MP4, MOV, or AVI video.';

  @override
  String get videoImportSizeError =>
      'The selected video exceeds the 2 GB limit.';

  @override
  String get videoImportValidationError =>
      'Unable to validate the selected video size.';

  @override
  String get videoImportError =>
      'Unable to select a video from the library. Please try again.';

  @override
  String get videoImportStorageError =>
      'Unable to prepare the selected video. Please try again.';

  @override
  String get restorationTitle => 'Wabi-Sabi restoration';

  @override
  String get restorationBody =>
      'Preserve every detail of your object\'s story.';

  @override
  String get automatic => 'Automatic';

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

  @override
  String get qualityReportTitle => 'Quality Report';

  @override
  String get qualityReportScanQuality => 'Scan quality';

  @override
  String qualityReportScore(String score) {
    return 'Score: $score out of 100';
  }

  @override
  String get qualityReportCategoryGreen => 'Good';

  @override
  String get qualityReportCategoryAmber => 'Warning';

  @override
  String get qualityReportCategoryRed => 'Poor';

  @override
  String get qualityReportEligible => 'Eligible';

  @override
  String qualityReportPhotosChecked(int count) {
    return '$count photos checked';
  }

  @override
  String get qualityReportPass => 'Pass';

  @override
  String get qualityReportWarn => 'Warning';

  @override
  String get qualityReportFail => 'Fail';

  @override
  String get qualityReportSuggestionTitle => 'Suggestions for improvement';

  @override
  String get qualityReportPhotoQuality => 'Photo quality';

  @override
  String get qualityReportAttentionPhotos => 'Photos needing attention';

  @override
  String qualityReportAttentionPhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String qualityReportViewAllPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'View all $count photos',
      one: 'View all 1 photo',
    );
    return '$_temp0';
  }

  @override
  String get qualityReportCollapsePhotos => 'Collapse';

  @override
  String get qualityReportAllPhotos => 'All photos';

  @override
  String get qualityReportStartReconstruction => 'Start reconstruction';

  @override
  String get qualityReportRecoverPhotos => 'Retake / Remove problem photos';

  @override
  String get qualityReportViewDetails => 'View details';

  @override
  String get qualityReportViewWarningDetails => 'View warning details';

  @override
  String get qualityReportViewErrorDetails => 'View error details';

  @override
  String get qualityReportDetailsTitle => 'Quality details';

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

  @override
  String get reconstructionConfirmationTitle => 'Confirm reconstruction';

  @override
  String get reconstructionConfirmationHero =>
      'Ready to create your 3D model? ✨';

  @override
  String get reconstructionConfirmationSubtitle =>
      'Review the details before starting reconstruction.';

  @override
  String reconstructionQualifiedCount(int count) {
    return '$count';
  }

  @override
  String get reconstructionQualifiedImages => 'Qualified images';

  @override
  String reconstructionQualityScore(int score) {
    return '$score%';
  }

  @override
  String get reconstructionQualityLabel => 'Overall quality';

  @override
  String get reconstructionQualityGreen => 'Good';

  @override
  String get reconstructionQualityAmber => 'Some limitations';

  @override
  String reconstructionEstimatedMinutes(int minutes) {
    return '~$minutes min';
  }

  @override
  String get reconstructionEstimatedTime => 'Estimated processing time';

  @override
  String get reconstructionProcessTitle => 'What happens next?';

  @override
  String get reconstructionProcessImages => 'Selected images';

  @override
  String get reconstructionProcessCloud => 'Cloud processing';

  @override
  String get reconstructionProcessModel => '3D model';

  @override
  String get reconstructionProcessBody =>
      'Your qualified images will be used to create the 3D model.';

  @override
  String get reconstructionResourceTitle => 'Before you start';

  @override
  String get reconstructionResourceBody =>
      '3D reconstruction uses processing resources and may take several minutes. Once started, it cannot be easily cancelled. Now is the easiest time to go back and check your images.';

  @override
  String get reconstructionAmberReminderTitle =>
      'Previously acknowledged warning';

  @override
  String get reconstructionAmberReminderBody =>
      'You have already acknowledged the quality warning. This image set still has some limitations, so the model may lose some detail.';

  @override
  String get reconstructionStart => 'Start reconstruction';

  @override
  String get reconstructionBackToReview => 'Back to image review';

  @override
  String get reconstructionSubmitting => 'Submitting…';

  @override
  String get reconstructionSubmitted => 'Submitted';

  @override
  String get reconstructionSubmissionError =>
      'Could not submit. Please try starting reconstruction again.';

  @override
  String get modelConfirmationTitle => 'Create 3D Model from Photos';

  @override
  String get modelConfirmationAiTooltip => '3D Forge AI assistant';

  @override
  String get modelConfirmationOriginalPhoto => 'Original photo';

  @override
  String get modelConfirmationKeepsakePhoto => 'Keepsake doll';

  @override
  String get modelConfirmationConsentBadge => '100% consented';

  @override
  String get modelConfirmationAllPhotos => 'All captured photos';

  @override
  String get modelConfirmationHeader => 'Create a 3D model from photos ✨';

  @override
  String modelConfirmationSubtitle(int count) {
    return 'We received $count photos to create a vivid 3D image.';
  }

  @override
  String get modelConfirmationInfo =>
      'Automatically convert photos into a complete 3D model in just a few taps';

  @override
  String get modelConfirmationUploadedTitle => 'Uploaded photos';

  @override
  String modelConfirmationUploadedValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sharp photos',
      zero: 'No sharp photos yet',
    );
    return '$_temp0';
  }

  @override
  String get modelConfirmationGeneratedTitle => '3D model output';

  @override
  String get modelConfirmationGeneratedValue => 'Sharp 3D model';

  @override
  String get modelConfirmationGenerating => 'Processing';

  @override
  String get modelConfirmationFormatTitle => 'File format';

  @override
  String get modelConfirmationFormatValue => '.GLB / 3D ready (.STL)';

  @override
  String get modelConfirmationFormatBadge => '3D standard';

  @override
  String get modelConfirmationWarning =>
      'No photos are ready yet. Go back and capture at least one photo before creating the 3D model.';

  @override
  String get modelConfirmationCta => 'Create 3D Model now';

  @override
  String get modelConfirmationSubmitting => 'Creating model...';

  @override
  String get modelConfirmationEstimate => 'Estimated time: 1–2 minutes';

  @override
  String get modelConfirmationError =>
      'Could not create the 3D model. Please try again.';

  @override
  String get processingSimulated => 'Simulated progress — demo only';

  @override
  String get processingTakesTime =>
      'Reconstruction may take some time. The current stage is shown below.';

  @override
  String get processingDemoCompleted => 'Simulation completed';

  @override
  String get processingDemoCompleteBody =>
      'This demo has finished. No 3D model was created.';

  @override
  String get processingDemoFailure =>
      'The simulation stopped while generating details. You can retry the demo.';

  @override
  String get processingSourceFailure =>
      'Progress updates could not be received.';

  @override
  String get processingStoppedHere => 'Stopped at this stage';

  @override
  String get processingReturn => 'Return';

  @override
  String get processingObservationAuth =>
      'Your session has ended. Sign in again to check progress.';

  @override
  String get processingObservationUnavailable =>
      'This reconstruction job is unavailable.';

  @override
  String get processingObservationContract =>
      'Progress could not be read. Please try again.';

  @override
  String get processingObservationTransient =>
      'Progress is temporarily unavailable. Retrying automatically.';

  @override
  String get processingObservationExhausted =>
      'Progress updates have stopped after repeated connection problems. Retry to check again.';

  @override
  String get processingObservationLoading => 'Retrieving reconstruction status';

  @override
  String get processingObservationLoadingBody =>
      'Please wait while we check the reconstruction job.';

  @override
  String get processingQueued => 'Queued';

  @override
  String get processingQueuedBody => 'Waiting for reconstruction.';

  @override
  String get processingCancelled => 'Cancelled';

  @override
  String get processingCancelledBody => 'Reconstruction was cancelled.';

  @override
  String get processingBackendReal => 'Backend processing';

  @override
  String get processingProvenanceUnknown => 'Processing mode not yet known';

  @override
  String get processingBackendDownloading => 'Downloading reconstruction input';

  @override
  String get processingBackendPreprocessing =>
      'Preprocessing reconstruction input';

  @override
  String get processingBackendShapeGeneration => 'Generating shape';

  @override
  String get processingBackendTexturing => 'Applying textures';

  @override
  String get processingBackendValidating => 'Validating reconstruction';

  @override
  String get processingBackendExporting => 'Exporting reconstruction';

  @override
  String get processingBackendUploading => 'Uploading reconstruction output';

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

  @override
  String get jobFailedHeaderTitle => 'Create 3D Model';

  @override
  String get jobFailedStatusBadge => 'Status: Failed';

  @override
  String get jobFailedTitle => 'Couldn\'t create the 3D model';

  @override
  String get jobFailedSubtitle =>
      'Some reconstruction steps encountered an issue. Don\'t worry, your captures are safe.';

  @override
  String get jobFailedCardTitle => 'What happened?';

  @override
  String get jobRetry => 'Retry 3D generation';

  @override
  String get jobRetrying => 'Retrying...';

  @override
  String get jobDashboard => 'Back to Dashboard';

  @override
  String get jobRetryLimit =>
      'You have exceeded the allowed retry attempts. Please contact support or create a new scan.';

  @override
  String get jobRetryFailedHint =>
      'Retry is unavailable right now. Check your connection and try again.';

  @override
  String get jobFailedIllustrationTag => '3D AI Engine';

  @override
  String get modelViewerTitle => '3D model';

  @override
  String get modelViewerModelReady => 'Model ready';

  @override
  String get modelViewerReadyExplanation =>
      'Your model is ready to explore. Rotate it to see it from every angle.';

  @override
  String get modelViewerPendingExplanation =>
      'Your model is being prepared. You can explore it when it is ready.';

  @override
  String get modelViewerUnavailableExplanation =>
      'A model is not available for this item yet.';

  @override
  String modelViewerReference(String code) {
    return 'Reference · $code';
  }

  @override
  String get modelViewerFormat => 'Format';

  @override
  String get modelViewerFormatGlb => 'GLB';

  @override
  String get modelViewerStatus => 'Status';

  @override
  String get modelViewerDetail => 'Detail';

  @override
  String get modelViewerDetailHigh => 'High';

  @override
  String modelViewerPercentage(int value) {
    return '$value%';
  }

  @override
  String get modelViewerContinue => 'Continue';

  @override
  String get modelViewerPreviewName => 'Little robot · Development preview';

  @override
  String get modelViewerPreviewAction =>
      'Preview only — no next screen is connected.';

  @override
  String get modelViewerPreviewTitle => '3D viewer preview';

  @override
  String get modelViewerInitializing => 'Starting 3D viewer…';

  @override
  String get modelViewerReady => '3D viewer ready';

  @override
  String get modelViewerShaded => 'Shaded';

  @override
  String get modelViewerWireframe => 'Wireframe';

  @override
  String get modelViewerGrid => 'Grid';

  @override
  String get modelViewerReset => 'Reset View';

  @override
  String get modelViewerInteractionHint => 'Rotate • Zoom • Pan';

  @override
  String get modelViewerLoading => 'Loading 3D model…';

  @override
  String get modelViewerLoaded => '3D model loaded';

  @override
  String get modelViewerLoadError => 'The 3D model could not be loaded.';

  @override
  String get modelViewerInitializationError =>
      'The 3D viewer could not start. Close this view and try again.';

  @override
  String get modelViewerScreenTitle => '3D Model Viewer';

  @override
  String get modelViewerFetchingOutputs => 'Fetching model information…';

  @override
  String get modelViewerDownloading => 'Downloading 3D model…';

  @override
  String get modelViewerNoPrimaryGlb =>
      'No primary GLB model is available for this scan.';

  @override
  String get modelViewerRetry => 'Retry';

  @override
  String get checkPrintabilityCta => 'Check Printability';

  @override
  String get rateAndShareCta => 'Rate & Share';

  @override
  String get orderPhysicalPrintCta => 'Order a physical print';
}
