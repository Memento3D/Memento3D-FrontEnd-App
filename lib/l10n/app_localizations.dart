import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @resetPasswordInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'Link expired'**
  String get resetPasswordInvalidTitle;

  /// No description provided for @resetPasswordInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'This password reset link cannot be used. Request a new link to continue.'**
  String get resetPasswordInvalidBody;

  /// No description provided for @resetPasswordRequestNewLink.
  ///
  /// In en, this message translates to:
  /// **'Request a new link'**
  String get resetPasswordRequestNewLink;

  /// No description provided for @resetPasswordBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get resetPasswordBackToLogin;

  /// No description provided for @resetPasswordSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Password reset successful'**
  String get resetPasswordSuccessTitle;

  /// No description provided for @resetPasswordSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset. Log in with your new password.'**
  String get resetPasswordSuccessBody;

  /// No description provided for @resetPasswordHeader.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordHeader;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new password'**
  String get resetPasswordTitle;

  /// No description provided for @resetPasswordSupport.
  ///
  /// In en, this message translates to:
  /// **'Create a new password for your account.'**
  String get resetPasswordSupport;

  /// No description provided for @resetPasswordNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetPasswordNewPassword;

  /// No description provided for @resetPasswordConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get resetPasswordConfirmPassword;

  /// No description provided for @resetPasswordShowPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get resetPasswordShowPassword;

  /// No description provided for @resetPasswordHidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get resetPasswordHidePassword;

  /// No description provided for @resetPasswordNewRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password.'**
  String get resetPasswordNewRequired;

  /// No description provided for @resetPasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get resetPasswordConfirmRequired;

  /// No description provided for @resetPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'The confirmation password does not match.'**
  String get resetPasswordMismatch;

  /// No description provided for @resetPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPasswordSubmit;

  /// No description provided for @resetPasswordSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Resetting password…'**
  String get resetPasswordSubmitting;

  /// No description provided for @resetPasswordTechnicalFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to reset your password right now. Please try again.'**
  String get resetPasswordTechnicalFailure;

  /// No description provided for @resetPasswordRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get resetPasswordRetry;

  /// No description provided for @resetPasswordCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get resetPasswordCancel;

  /// No description provided for @forgotPasswordSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Sending request…'**
  String get forgotPasswordSubmitting;

  /// No description provided for @forgotPasswordSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get forgotPasswordSentTitle;

  /// No description provided for @forgotPasswordSentBody.
  ///
  /// In en, this message translates to:
  /// **'If the email exists, you will receive instructions to reset your password.'**
  String get forgotPasswordSentBody;

  /// No description provided for @forgotPasswordSentSupport.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox and follow the link in the email to continue.'**
  String get forgotPasswordSentSupport;

  /// No description provided for @forgotPasswordGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'No email yet?'**
  String get forgotPasswordGuidanceTitle;

  /// No description provided for @forgotPasswordSpamGuidance.
  ///
  /// In en, this message translates to:
  /// **'Check your Spam / Junk folder.'**
  String get forgotPasswordSpamGuidance;

  /// No description provided for @forgotPasswordDeliveryGuidance.
  ///
  /// In en, this message translates to:
  /// **'Delivery may take a few minutes.'**
  String get forgotPasswordDeliveryGuidance;

  /// No description provided for @forgotPasswordResend.
  ///
  /// In en, this message translates to:
  /// **'Resend instructions'**
  String get forgotPasswordResend;

  /// No description provided for @forgotPasswordResending.
  ///
  /// In en, this message translates to:
  /// **'Resending instructions…'**
  String get forgotPasswordResending;

  /// No description provided for @forgotPasswordTechnicalFailure.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the request right now. Please try again.'**
  String get forgotPasswordTechnicalFailure;

  /// No description provided for @forgotPasswordRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get forgotPasswordRetry;

  /// No description provided for @forgotPasswordHeader.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPasswordHeader;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t worry, we\'ll help you regain access.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @forgotPasswordEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get forgotPasswordEmailLabel;

  /// No description provided for @forgotPasswordEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get forgotPasswordEmailHint;

  /// No description provided for @forgotPasswordEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you used to create your account.'**
  String get forgotPasswordEmailHelper;

  /// No description provided for @forgotPasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send reset instructions'**
  String get forgotPasswordSubmit;

  /// No description provided for @forgotPasswordCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get forgotPasswordCancel;

  /// No description provided for @forgotPasswordBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get forgotPasswordBackToLogin;

  /// No description provided for @forgotPasswordEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get forgotPasswordEmailRequired;

  /// No description provided for @emailVerificationAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Check that the email address above is correct.'**
  String get emailVerificationAddressHint;

  /// No description provided for @emailVerificationDeliveryHint.
  ///
  /// In en, this message translates to:
  /// **'Email delivery may take a little time.'**
  String get emailVerificationDeliveryHint;

  /// No description provided for @emailVerificationVerifyingHint.
  ///
  /// In en, this message translates to:
  /// **'Please wait while your verification link is checked.'**
  String get emailVerificationVerifyingHint;

  /// No description provided for @emailVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get emailVerificationTitle;

  /// No description provided for @emailVerificationHeading.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get emailVerificationHeading;

  /// No description provided for @emailVerificationSentBody.
  ///
  /// In en, this message translates to:
  /// **'A verification link has been sent to:'**
  String get emailVerificationSentBody;

  /// No description provided for @emailVerificationInstruction.
  ///
  /// In en, this message translates to:
  /// **'Open the verification link in your email to confirm your address.'**
  String get emailVerificationInstruction;

  /// No description provided for @emailVerificationWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification…'**
  String get emailVerificationWaiting;

  /// No description provided for @emailVerificationWaitingBody.
  ///
  /// In en, this message translates to:
  /// **'Follow the email link to verify your address. You can continue once verification is confirmed.'**
  String get emailVerificationWaitingBody;

  /// No description provided for @emailVerificationResendTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find the email?'**
  String get emailVerificationResendTitle;

  /// No description provided for @emailVerificationSpamHint.
  ///
  /// In en, this message translates to:
  /// **'Check your Spam or Junk folder, or request another verification email.'**
  String get emailVerificationSpamHint;

  /// No description provided for @emailVerificationResend.
  ///
  /// In en, this message translates to:
  /// **'Resend verification email'**
  String get emailVerificationResend;

  /// No description provided for @emailVerificationSending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get emailVerificationSending;

  /// No description provided for @emailVerificationResendSuccess.
  ///
  /// In en, this message translates to:
  /// **'A new verification email has been sent. Check your inbox.'**
  String get emailVerificationResendSuccess;

  /// No description provided for @emailVerificationResendFailure.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t send the email. Please try again.'**
  String get emailVerificationResendFailure;

  /// No description provided for @emailVerificationRetryAfter.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds} seconds'**
  String emailVerificationRetryAfter(int seconds);

  /// No description provided for @emailVerificationVerifying.
  ///
  /// In en, this message translates to:
  /// **'Verifying your email…'**
  String get emailVerificationVerifying;

  /// No description provided for @emailVerificationVerifyingBody.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we check your verification link.'**
  String get emailVerificationVerifyingBody;

  /// No description provided for @emailVerificationSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Email verified!'**
  String get emailVerificationSuccessTitle;

  /// No description provided for @emailVerificationSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Your email address has been confirmed. You can continue to the next step.'**
  String get emailVerificationSuccessBody;

  /// No description provided for @emailVerificationContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get emailVerificationContinue;

  /// No description provided for @emailVerificationInvalidTitle.
  ///
  /// In en, this message translates to:
  /// **'This link is no longer valid'**
  String get emailVerificationInvalidTitle;

  /// No description provided for @emailVerificationInvalidBody.
  ///
  /// In en, this message translates to:
  /// **'The verification link may have expired or be invalid. Request a new email to try again.'**
  String get emailVerificationInvalidBody;

  /// No description provided for @emailVerificationResendNew.
  ///
  /// In en, this message translates to:
  /// **'Send a new verification email'**
  String get emailVerificationResendNew;

  /// No description provided for @emailVerificationFailure.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t check your link. Please try again when your connection is available.'**
  String get emailVerificationFailure;

  /// No description provided for @emailVerificationUnknownEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address is unavailable. Return to registration to request another verification email.'**
  String get emailVerificationUnknownEmail;

  /// No description provided for @captureTitle.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get captureTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @moveSlowly.
  ///
  /// In en, this message translates to:
  /// **'✨ Move slowly around the object 🌸'**
  String get moveSlowly;

  /// No description provided for @keepStill.
  ///
  /// In en, this message translates to:
  /// **'Keep the object still and maintain a steady distance.'**
  String get keepStill;

  /// No description provided for @capturedPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count} photos captured'**
  String capturedPhotos(int count);

  /// No description provided for @orbitLabel.
  ///
  /// In en, this message translates to:
  /// **'360° Orbit'**
  String get orbitLabel;

  /// No description provided for @distanceGood.
  ///
  /// In en, this message translates to:
  /// **'Distance good'**
  String get distanceGood;

  /// No description provided for @balanceGood.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get balanceGood;

  /// No description provided for @naturalLight.
  ///
  /// In en, this message translates to:
  /// **'Natural light'**
  String get naturalLight;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @photo.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get photo;

  /// No description provided for @video.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get video;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @nextStep.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No camera found on this device.'**
  String get cameraUnavailable;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Could not open camera.'**
  String get cameraError;

  /// No description provided for @captureError.
  ///
  /// In en, this message translates to:
  /// **'Could not capture photo.'**
  String get captureError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @capturePhoto.
  ///
  /// In en, this message translates to:
  /// **'Capture photo'**
  String get capturePhoto;

  /// No description provided for @photoCaptured.
  ///
  /// In en, this message translates to:
  /// **'Photo captured'**
  String get photoCaptured;

  /// No description provided for @wizardReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Move slowly around the object'**
  String get wizardReadyTitle;

  /// No description provided for @wizardReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Keep the object still and maintain a stable distance.'**
  String get wizardReadyBody;

  /// No description provided for @wizardTiltedTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep your phone straight'**
  String get wizardTiltedTitle;

  /// No description provided for @wizardTiltedBody.
  ///
  /// In en, this message translates to:
  /// **'Adjust the phone orientation before continuing.'**
  String get wizardTiltedBody;

  /// No description provided for @wizardMovingTitle.
  ///
  /// In en, this message translates to:
  /// **'Move more slowly'**
  String get wizardMovingTitle;

  /// No description provided for @wizardMovingBody.
  ///
  /// In en, this message translates to:
  /// **'Slow movement helps capture clearer views.'**
  String get wizardMovingBody;

  /// No description provided for @wizardCapturedTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo captured'**
  String get wizardCapturedTitle;

  /// No description provided for @wizardCapturedBody.
  ///
  /// In en, this message translates to:
  /// **'Continue moving around the object.'**
  String get wizardCapturedBody;

  /// No description provided for @reviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// No description provided for @captureSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Object capture session'**
  String get captureSessionTitle;

  /// No description provided for @sessionPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get sessionPhotoCount;

  /// No description provided for @sessionFileSize.
  ///
  /// In en, this message translates to:
  /// **'File size'**
  String get sessionFileSize;

  /// No description provided for @sessionQuality.
  ///
  /// In en, this message translates to:
  /// **'3D quality'**
  String get sessionQuality;

  /// No description provided for @metricUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get metricUnavailable;

  /// No description provided for @sizeCalculating.
  ///
  /// In en, this message translates to:
  /// **'Calculating'**
  String get sizeCalculating;

  /// No description provided for @sizeIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Some files unavailable'**
  String get sizeIncomplete;

  /// No description provided for @fileSizeKb.
  ///
  /// In en, this message translates to:
  /// **'{value} KB'**
  String fileSizeKb(String value);

  /// No description provided for @fileSizeMb.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String fileSizeMb(String value);

  /// No description provided for @capturedPhotoSection.
  ///
  /// In en, this message translates to:
  /// **'Captured photos'**
  String get capturedPhotoSection;

  /// No description provided for @addAngle.
  ///
  /// In en, this message translates to:
  /// **'Add angle'**
  String get addAngle;

  /// No description provided for @addAngleHint.
  ///
  /// In en, this message translates to:
  /// **'Capture another view'**
  String get addAngleHint;

  /// No description provided for @photoNumber.
  ///
  /// In en, this message translates to:
  /// **'Photo {number}'**
  String photoNumber(int number);

  /// No description provided for @imageUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Image unavailable'**
  String get imageUnavailable;

  /// No description provided for @deletePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get deletePhoto;

  /// No description provided for @retakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get retakePhoto;

  /// No description provided for @closePreview.
  ///
  /// In en, this message translates to:
  /// **'Close preview'**
  String get closePreview;

  /// No description provided for @detailTitle.
  ///
  /// In en, this message translates to:
  /// **'Detail level'**
  String get detailTitle;

  /// No description provided for @detailSubtitle.
  ///
  /// In en, this message translates to:
  /// **'For future 3D reconstruction'**
  String get detailSubtitle;

  /// No description provided for @detailStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get detailStandard;

  /// No description provided for @detailStandardDescription.
  ///
  /// In en, this message translates to:
  /// **'Suitable for quick web and mobile previews.'**
  String get detailStandardDescription;

  /// No description provided for @detailHigh.
  ///
  /// In en, this message translates to:
  /// **'High detail'**
  String get detailHigh;

  /// No description provided for @detailHighDescription.
  ///
  /// In en, this message translates to:
  /// **'Preserve more surface detail for a future 3D model.'**
  String get detailHighDescription;

  /// No description provided for @detailSelectionOnly.
  ///
  /// In en, this message translates to:
  /// **'Selection only — reconstruction is not available yet.'**
  String get detailSelectionOnly;

  /// No description provided for @modelPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'3D preview unavailable'**
  String get modelPreviewUnavailable;

  /// No description provided for @processingCta.
  ///
  /// In en, this message translates to:
  /// **'View processing status'**
  String get processingCta;

  /// No description provided for @processingTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processingTitle;

  /// No description provided for @processingLocal.
  ///
  /// In en, this message translates to:
  /// **'Local capture session'**
  String get processingLocal;

  /// No description provided for @processingCloudUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Cloud service not connected'**
  String get processingCloudUnavailable;

  /// No description provided for @processingPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photos captured'**
  String processingPhotoCount(int count);

  /// No description provided for @processingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to upload'**
  String get processingReadyTitle;

  /// No description provided for @processingReadyBody.
  ///
  /// In en, this message translates to:
  /// **'Your photos are prepared locally. Processing will be available when a service is connected.'**
  String get processingReadyBody;

  /// No description provided for @processingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for processing service'**
  String get processingWaiting;

  /// No description provided for @processingProgressPending.
  ///
  /// In en, this message translates to:
  /// **'Progress will appear here when processing starts.'**
  String get processingProgressPending;

  /// No description provided for @processingStageTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing stages'**
  String get processingStageTitle;

  /// No description provided for @processingStagePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get processingStagePending;

  /// No description provided for @processingStageActive.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get processingStageActive;

  /// No description provided for @processingStageCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get processingStageCompleted;

  /// No description provided for @processingStageUpload.
  ///
  /// In en, this message translates to:
  /// **'Data upload'**
  String get processingStageUpload;

  /// No description provided for @processingStagePrepare.
  ///
  /// In en, this message translates to:
  /// **'Image preparation'**
  String get processingStagePrepare;

  /// No description provided for @processingStageStructure.
  ///
  /// In en, this message translates to:
  /// **'3D structure reconstruction'**
  String get processingStageStructure;

  /// No description provided for @processingStageDetail.
  ///
  /// In en, this message translates to:
  /// **'Detail generation'**
  String get processingStageDetail;

  /// No description provided for @processingStageTexture.
  ///
  /// In en, this message translates to:
  /// **'Texturing and finalization'**
  String get processingStageTexture;

  /// No description provided for @processingStageComplete.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get processingStageComplete;

  /// No description provided for @processingSelectedDetail.
  ///
  /// In en, this message translates to:
  /// **'Selected detail'**
  String get processingSelectedDetail;

  /// No description provided for @processingFileSize.
  ///
  /// In en, this message translates to:
  /// **'Local file size'**
  String get processingFileSize;

  /// No description provided for @processingMissingImage.
  ///
  /// In en, this message translates to:
  /// **'Captured image unavailable'**
  String get processingMissingImage;

  /// No description provided for @processingNotStarted.
  ///
  /// In en, this message translates to:
  /// **'No upload or reconstruction has started.'**
  String get processingNotStarted;

  /// No description provided for @processingUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos'**
  String get processingUploading;

  /// No description provided for @processingRunning.
  ///
  /// In en, this message translates to:
  /// **'Processing photos'**
  String get processingRunning;

  /// No description provided for @processingCompleted.
  ///
  /// In en, this message translates to:
  /// **'Processing completed'**
  String get processingCompleted;

  /// No description provided for @processingFailed.
  ///
  /// In en, this message translates to:
  /// **'Processing failed'**
  String get processingFailed;

  /// No description provided for @processingCloudConnected.
  ///
  /// In en, this message translates to:
  /// **'Processing service connected'**
  String get processingCloudConnected;

  /// No description provided for @processingInProgressBody.
  ///
  /// In en, this message translates to:
  /// **'Progress is based on service updates.'**
  String get processingInProgressBody;

  /// No description provided for @processingCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'The processing service reports completion.'**
  String get processingCompleteBody;

  /// No description provided for @processingFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The processing service reported a problem.'**
  String get processingFailedBody;

  /// No description provided for @captureLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get captureLibrary;

  /// No description provided for @captureCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get captureCollection;

  /// No description provided for @capturePrints.
  ///
  /// In en, this message translates to:
  /// **'Prints'**
  String get capturePrints;

  /// No description provided for @captureStudio.
  ///
  /// In en, this message translates to:
  /// **'Creation Studio'**
  String get captureStudio;

  /// No description provided for @captureSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get captureSettings;

  /// No description provided for @captureCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get captureCamera;

  /// No description provided for @recordVideo.
  ///
  /// In en, this message translates to:
  /// **'Record video'**
  String get recordVideo;

  /// No description provided for @stopVideo.
  ///
  /// In en, this message translates to:
  /// **'Stop recording'**
  String get stopVideo;

  /// No description provided for @videoStartError.
  ///
  /// In en, this message translates to:
  /// **'Video recording could not start. Try again.'**
  String get videoStartError;

  /// No description provided for @videoFinalizeError.
  ///
  /// In en, this message translates to:
  /// **'Video could not be finalized. Try recording again.'**
  String get videoFinalizeError;

  /// No description provided for @recordedVideo.
  ///
  /// In en, this message translates to:
  /// **'Recorded video'**
  String get recordedVideo;

  /// No description provided for @videoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Video unavailable'**
  String get videoUnavailable;

  /// No description provided for @videoFileChanged.
  ///
  /// In en, this message translates to:
  /// **'File has changed since recording. Size shown is from finalization.'**
  String get videoFileChanged;

  /// No description provided for @videoPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Video preview'**
  String get videoPreviewTitle;

  /// No description provided for @videoFinalizedSize.
  ///
  /// In en, this message translates to:
  /// **'Size at capture'**
  String get videoFinalizedSize;

  /// No description provided for @videoNotSelected.
  ///
  /// In en, this message translates to:
  /// **'No video selected'**
  String get videoNotSelected;

  /// No description provided for @videoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get videoLoading;

  /// No description provided for @videoPlay.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get videoPlay;

  /// No description provided for @videoPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get videoPause;

  /// No description provided for @videoDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration: {duration}'**
  String videoDuration(String duration);

  /// No description provided for @videoTooShort.
  ///
  /// In en, this message translates to:
  /// **'Video must be at least {seconds} seconds long.'**
  String videoTooShort(int seconds);

  /// No description provided for @videoDurationSatisfied.
  ///
  /// In en, this message translates to:
  /// **'Minimum duration met.'**
  String get videoDurationSatisfied;

  /// No description provided for @videoPlaybackError.
  ///
  /// In en, this message translates to:
  /// **'This video couldn’t be played. Try recording another video.'**
  String get videoPlaybackError;

  /// No description provided for @importedVideo.
  ///
  /// In en, this message translates to:
  /// **'Imported video'**
  String get importedVideo;

  /// No description provided for @videoReplaceFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Replace from library'**
  String get videoReplaceFromLibrary;

  /// No description provided for @videoImportFormatError.
  ///
  /// In en, this message translates to:
  /// **'Select an MP4, MOV, or AVI video.'**
  String get videoImportFormatError;

  /// No description provided for @videoImportSizeError.
  ///
  /// In en, this message translates to:
  /// **'The selected video exceeds the 2 GB limit.'**
  String get videoImportSizeError;

  /// No description provided for @videoImportValidationError.
  ///
  /// In en, this message translates to:
  /// **'Unable to validate the selected video size.'**
  String get videoImportValidationError;

  /// No description provided for @videoImportError.
  ///
  /// In en, this message translates to:
  /// **'Unable to select a video from the library. Please try again.'**
  String get videoImportError;

  /// No description provided for @videoImportStorageError.
  ///
  /// In en, this message translates to:
  /// **'Unable to prepare the selected video. Please try again.'**
  String get videoImportStorageError;

  /// No description provided for @restorationTitle.
  ///
  /// In en, this message translates to:
  /// **'Wabi-Sabi restoration'**
  String get restorationTitle;

  /// No description provided for @restorationBody.
  ///
  /// In en, this message translates to:
  /// **'Preserve every detail of your object\'s story.'**
  String get restorationBody;

  /// No description provided for @automatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get automatic;

  /// No description provided for @uploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos'**
  String get uploadTitle;

  /// No description provided for @uploadPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing upload'**
  String get uploadPreparing;

  /// No description provided for @uploadUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploadUploading;

  /// No description provided for @uploadWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for connection'**
  String get uploadWaiting;

  /// No description provided for @uploadReconciling.
  ///
  /// In en, this message translates to:
  /// **'Restoring upload'**
  String get uploadReconciling;

  /// No description provided for @uploadRetryNeeded.
  ///
  /// In en, this message translates to:
  /// **'Retry needed'**
  String get uploadRetryNeeded;

  /// No description provided for @uploadCompleted.
  ///
  /// In en, this message translates to:
  /// **'Photo upload complete'**
  String get uploadCompleted;

  /// No description provided for @uploadMainTitle.
  ///
  /// In en, this message translates to:
  /// **'Uploading your photos'**
  String get uploadMainTitle;

  /// No description provided for @uploadNetworkBanner.
  ///
  /// In en, this message translates to:
  /// **'Waiting to reconnect'**
  String get uploadNetworkBanner;

  /// No description provided for @uploadNetworkBody.
  ///
  /// In en, this message translates to:
  /// **'Confirmed progress is unchanged. Uploading will continue when the connection returns.'**
  String get uploadNetworkBody;

  /// No description provided for @uploadReconcilingTitle.
  ///
  /// In en, this message translates to:
  /// **'Restoring your upload session'**
  String get uploadReconcilingTitle;

  /// No description provided for @uploadReconcilingBody.
  ///
  /// In en, this message translates to:
  /// **'Checking the last confirmed position before continuing. Your progress stays unchanged while we check.'**
  String get uploadReconcilingBody;

  /// No description provided for @uploadCompletionBody.
  ///
  /// In en, this message translates to:
  /// **'Moving to quality check...'**
  String get uploadCompletionBody;

  /// No description provided for @uploadFailureBody.
  ///
  /// In en, this message translates to:
  /// **'Your confirmed progress is unchanged. Try again to continue from the last confirmed position.'**
  String get uploadFailureBody;

  /// No description provided for @uploadSourceFailureBody.
  ///
  /// In en, this message translates to:
  /// **'Upload updates are unavailable. Your confirmed progress is unchanged; try again to reconnect.'**
  String get uploadSourceFailureBody;

  /// No description provided for @uploadLocalPhotos.
  ///
  /// In en, this message translates to:
  /// **'Local photos'**
  String get uploadLocalPhotos;

  /// No description provided for @uploadSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress is saved automatically'**
  String get uploadSavedTitle;

  /// No description provided for @uploadSavedBody.
  ///
  /// In en, this message translates to:
  /// **'You can return to this upload after an interruption. It will continue from the last confirmed position.'**
  String get uploadSavedBody;

  /// No description provided for @uploadSessionOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep this session open'**
  String get uploadSessionOnlyTitle;

  /// No description provided for @uploadSessionOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Confirmed progress remains visible in this session. Recovery after closing the app is not available yet.'**
  String get uploadSessionOnlyBody;

  /// No description provided for @uploadPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String uploadPhotoCount(int count);

  /// No description provided for @uploadPercent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String uploadPercent(String value);

  /// No description provided for @uploadSummaryProgress.
  ///
  /// In en, this message translates to:
  /// **'{value}% uploaded'**
  String uploadSummaryProgress(String value);

  /// No description provided for @uploadUnitCount.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} / {total}'**
  String uploadUnitCount(int confirmed, int total);

  /// No description provided for @uploadConfirmedParts.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} / {total} parts uploaded'**
  String uploadConfirmedParts(int confirmed, int total);

  /// No description provided for @uploadProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirmed upload progress'**
  String get uploadProgressLabel;

  /// No description provided for @uploadSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get uploadSpeed;

  /// No description provided for @uploadSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'{value} MB/s'**
  String uploadSpeedValue(String value);

  /// No description provided for @uploadRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get uploadRemaining;

  /// No description provided for @uploadEtaValue.
  ///
  /// In en, this message translates to:
  /// **'~{minutes}m {seconds}s'**
  String uploadEtaValue(int minutes, int seconds);

  /// No description provided for @uploadEtaWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get uploadEtaWaiting;

  /// No description provided for @uploadUnknownMetric.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get uploadUnknownMetric;

  /// No description provided for @uploadConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadConfirmed;

  /// No description provided for @uploadPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos in this upload'**
  String get uploadPhotosTitle;

  /// No description provided for @uploadPhotoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploadPhotoCompleted;

  /// No description provided for @uploadPhotoCurrent.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploadPhotoCurrent;

  /// No description provided for @uploadPhotoPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get uploadPhotoPending;

  /// No description provided for @uploadPhotoPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get uploadPhotoPaused;

  /// No description provided for @uploadPhotoDescription.
  ///
  /// In en, this message translates to:
  /// **'{photo}. {status}'**
  String uploadPhotoDescription(String photo, String status);

  /// No description provided for @uploadNextSteps.
  ///
  /// In en, this message translates to:
  /// **'Next steps'**
  String get uploadNextSteps;

  /// No description provided for @uploadCloudStep.
  ///
  /// In en, this message translates to:
  /// **'Upload to the cloud'**
  String get uploadCloudStep;

  /// No description provided for @uploadStepProgress.
  ///
  /// In en, this message translates to:
  /// **'{status} ({confirmed}/{total} parts)'**
  String uploadStepProgress(String status, int confirmed, int total);

  /// No description provided for @uploadQualityStep.
  ///
  /// In en, this message translates to:
  /// **'Quality check & preparation'**
  String get uploadQualityStep;

  /// No description provided for @uploadQualityNextBody.
  ///
  /// In en, this message translates to:
  /// **'The next step after upload'**
  String get uploadQualityNextBody;

  /// No description provided for @uploadNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get uploadNext;

  /// No description provided for @photoUploadComplete.
  ///
  /// In en, this message translates to:
  /// **'All photos have confirmed upload results. You can return to capture.'**
  String get photoUploadComplete;

  /// No description provided for @photoUploadRetrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying the photo that was not submitted'**
  String get photoUploadRetrying;

  /// No description provided for @photoUploadConfirm.
  ///
  /// In en, this message translates to:
  /// **'Upload photos'**
  String get photoUploadConfirm;

  /// No description provided for @photoUploadStopped.
  ///
  /// In en, this message translates to:
  /// **'Upload stopped'**
  String get photoUploadStopped;

  /// No description provided for @photoUploadAmbiguous.
  ///
  /// In en, this message translates to:
  /// **'The upload result for the current photo could not be confirmed. It may already exist on the server. Upload stopped; this photo will not be sent again.'**
  String get photoUploadAmbiguous;

  /// No description provided for @photoUploadRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected this photo. Upload stopped. Previously confirmed photos are retained.'**
  String get photoUploadRejected;

  /// No description provided for @photoUploadNotSubmitted.
  ///
  /// In en, this message translates to:
  /// **'This photo was not submitted. Check the local file, then retry explicitly.'**
  String get photoUploadNotSubmitted;

  /// No description provided for @photoUploadConfirmed.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} / {total} photos confirmed'**
  String photoUploadConfirmed(int confirmed, int total);

  /// No description provided for @qualityReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality Report'**
  String get qualityReportTitle;

  /// No description provided for @qualityReportScanQuality.
  ///
  /// In en, this message translates to:
  /// **'Scan quality'**
  String get qualityReportScanQuality;

  /// No description provided for @qualityReportScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score} out of 100'**
  String qualityReportScore(String score);

  /// No description provided for @qualityReportCategoryGreen.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get qualityReportCategoryGreen;

  /// No description provided for @qualityReportCategoryAmber.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get qualityReportCategoryAmber;

  /// No description provided for @qualityReportCategoryRed.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get qualityReportCategoryRed;

  /// No description provided for @qualityReportEligible.
  ///
  /// In en, this message translates to:
  /// **'Eligible'**
  String get qualityReportEligible;

  /// No description provided for @qualityReportPhotosChecked.
  ///
  /// In en, this message translates to:
  /// **'{count} photos checked'**
  String qualityReportPhotosChecked(int count);

  /// No description provided for @qualityReportPass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get qualityReportPass;

  /// No description provided for @qualityReportWarn.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get qualityReportWarn;

  /// No description provided for @qualityReportFail.
  ///
  /// In en, this message translates to:
  /// **'Fail'**
  String get qualityReportFail;

  /// No description provided for @qualityReportSuggestionTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions for improvement'**
  String get qualityReportSuggestionTitle;

  /// No description provided for @qualityReportPhotoQuality.
  ///
  /// In en, this message translates to:
  /// **'Photo quality'**
  String get qualityReportPhotoQuality;

  /// No description provided for @qualityReportAttentionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos needing attention'**
  String get qualityReportAttentionPhotos;

  /// No description provided for @qualityReportAttentionPhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 photo} other{{count} photos}}'**
  String qualityReportAttentionPhotoCount(int count);

  /// No description provided for @qualityReportViewAllPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{View all 1 photo} other{View all {count} photos}}'**
  String qualityReportViewAllPhotos(int count);

  /// No description provided for @qualityReportCollapsePhotos.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get qualityReportCollapsePhotos;

  /// No description provided for @qualityReportAllPhotos.
  ///
  /// In en, this message translates to:
  /// **'All photos'**
  String get qualityReportAllPhotos;

  /// No description provided for @qualityReportStartReconstruction.
  ///
  /// In en, this message translates to:
  /// **'Start reconstruction'**
  String get qualityReportStartReconstruction;

  /// No description provided for @qualityReportRecoverPhotos.
  ///
  /// In en, this message translates to:
  /// **'Retake / Remove problem photos'**
  String get qualityReportRecoverPhotos;

  /// No description provided for @qualityReportViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View details'**
  String get qualityReportViewDetails;

  /// No description provided for @qualityReportViewWarningDetails.
  ///
  /// In en, this message translates to:
  /// **'View warning details'**
  String get qualityReportViewWarningDetails;

  /// No description provided for @qualityReportViewErrorDetails.
  ///
  /// In en, this message translates to:
  /// **'View error details'**
  String get qualityReportViewErrorDetails;

  /// No description provided for @qualityReportDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quality details'**
  String get qualityReportDetailsTitle;

  /// No description provided for @qualityRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm risks'**
  String get qualityRiskTitle;

  /// No description provided for @qualityNeedsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMATION NEEDED'**
  String get qualityNeedsConfirmation;

  /// No description provided for @qualityHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Image quality is not fully optimal'**
  String get qualityHeroTitle;

  /// No description provided for @qualityHeroBody.
  ///
  /// In en, this message translates to:
  /// **'Reconstruction is still possible, but some images may affect the accuracy of your 3D model.'**
  String get qualityHeroBody;

  /// No description provided for @qualitySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Image quality summary'**
  String get qualitySummaryTitle;

  /// No description provided for @qualityQualified.
  ///
  /// In en, this message translates to:
  /// **'Qualified'**
  String get qualityQualified;

  /// No description provided for @qualityNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get qualityNeedsAttention;

  /// No description provided for @qualityOverallScore.
  ///
  /// In en, this message translates to:
  /// **'Overall quality'**
  String get qualityOverallScore;

  /// No description provided for @qualityPercentage.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String qualityPercentage(String value);

  /// No description provided for @qualityReviewImages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Review quality warnings} =1{1 image needs review} other{{count} images need review}}'**
  String qualityReviewImages(int count);

  /// No description provided for @qualityViewDetails.
  ///
  /// In en, this message translates to:
  /// **'View warnings and potential impact'**
  String get qualityViewDetails;

  /// No description provided for @qualityRiskDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Check before continuing'**
  String get qualityRiskDetailsTitle;

  /// No description provided for @qualityRiskDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Review the quality warnings before deciding.} =1{Review the possible impact of 1 image before deciding.} other{Review the possible impact of {count} images before deciding.}}'**
  String qualityRiskDetailsSubtitle(int count);

  /// No description provided for @qualityAffectedImages.
  ///
  /// In en, this message translates to:
  /// **'Images needing attention'**
  String get qualityAffectedImages;

  /// No description provided for @qualityAdditionalAffectedImages.
  ///
  /// In en, this message translates to:
  /// **'{count} additional images need attention'**
  String qualityAdditionalAffectedImages(int count);

  /// No description provided for @qualityNoAffectedImages.
  ///
  /// In en, this message translates to:
  /// **'No affected images to preview.'**
  String get qualityNoAffectedImages;

  /// No description provided for @qualityImpactTitle.
  ///
  /// In en, this message translates to:
  /// **'What could this affect?'**
  String get qualityImpactTitle;

  /// No description provided for @qualitySurfaceRisk.
  ///
  /// In en, this message translates to:
  /// **'Surface details may be less sharp in some areas.'**
  String get qualitySurfaceRisk;

  /// No description provided for @qualityGeometryRisk.
  ///
  /// In en, this message translates to:
  /// **'Geometry may be slightly less accurate in poorly captured areas.'**
  String get qualityGeometryRisk;

  /// No description provided for @qualityReassurance.
  ///
  /// In en, this message translates to:
  /// **'You can continue with these images, or go back to improve the capture for potentially better results.'**
  String get qualityReassurance;

  /// No description provided for @qualityAcknowledgement.
  ///
  /// In en, this message translates to:
  /// **'I understand the risks and still want to continue'**
  String get qualityAcknowledgement;

  /// No description provided for @qualityAcknowledgementHint.
  ///
  /// In en, this message translates to:
  /// **'Quality warnings may affect the final 3D result. Confirm only when you are ready to accept these risks.'**
  String get qualityAcknowledgementHint;

  /// No description provided for @qualityCloseDetails.
  ///
  /// In en, this message translates to:
  /// **'Close risk details'**
  String get qualityCloseDetails;

  /// No description provided for @qualityContextChanged.
  ///
  /// In en, this message translates to:
  /// **'The quality report changed. Close this sheet and review the current report.'**
  String get qualityContextChanged;

  /// No description provided for @qualityContinue.
  ///
  /// In en, this message translates to:
  /// **'Confirm and continue'**
  String get qualityContinue;

  /// No description provided for @qualitySubmitting.
  ///
  /// In en, this message translates to:
  /// **'Confirming…'**
  String get qualitySubmitting;

  /// No description provided for @qualityBackToImages.
  ///
  /// In en, this message translates to:
  /// **'Go back to review images'**
  String get qualityBackToImages;

  /// No description provided for @qualityBackToReport.
  ///
  /// In en, this message translates to:
  /// **'Go back to the quality report'**
  String get qualityBackToReport;

  /// No description provided for @qualityBlockedStatus.
  ///
  /// In en, this message translates to:
  /// **'UNABLE TO CONTINUE'**
  String get qualityBlockedStatus;

  /// No description provided for @qualityRejectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Cannot continue with these images'**
  String get qualityRejectedTitle;

  /// No description provided for @qualityRejectedBody.
  ///
  /// In en, this message translates to:
  /// **'The current image quality is not suitable for continuing. Please go back to review your images.'**
  String get qualityRejectedBody;

  /// No description provided for @qualityIneligibleStatus.
  ///
  /// In en, this message translates to:
  /// **'REVIEW REQUIRED'**
  String get qualityIneligibleStatus;

  /// No description provided for @qualityIneligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'Please return to the quality report'**
  String get qualityIneligibleTitle;

  /// No description provided for @qualityIneligibleBody.
  ///
  /// In en, this message translates to:
  /// **'Risk confirmation is not available for this report. Go back to review the current image quality.'**
  String get qualityIneligibleBody;

  /// No description provided for @qualityRecoverableFailure.
  ///
  /// In en, this message translates to:
  /// **'We could not confirm your request. Your acknowledgement is saved; please try again.'**
  String get qualityRecoverableFailure;

  /// No description provided for @qualityRetry.
  ///
  /// In en, this message translates to:
  /// **'Try confirmation again'**
  String get qualityRetry;

  /// No description provided for @qualityConfirmedStatus.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get qualityConfirmedStatus;

  /// No description provided for @qualityConfirmedTitle.
  ///
  /// In en, this message translates to:
  /// **'Risks confirmed'**
  String get qualityConfirmedTitle;

  /// No description provided for @qualityConfirmedBody.
  ///
  /// In en, this message translates to:
  /// **'Your confirmation has been accepted.'**
  String get qualityConfirmedBody;

  /// No description provided for @reconstructionConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm reconstruction'**
  String get reconstructionConfirmationTitle;

  /// No description provided for @reconstructionConfirmationHero.
  ///
  /// In en, this message translates to:
  /// **'Ready to create your 3D model? ✨'**
  String get reconstructionConfirmationHero;

  /// No description provided for @reconstructionConfirmationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review the details before starting reconstruction.'**
  String get reconstructionConfirmationSubtitle;

  /// No description provided for @reconstructionQualifiedCount.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String reconstructionQualifiedCount(int count);

  /// No description provided for @reconstructionQualifiedImages.
  ///
  /// In en, this message translates to:
  /// **'Qualified images'**
  String get reconstructionQualifiedImages;

  /// No description provided for @reconstructionQualityScore.
  ///
  /// In en, this message translates to:
  /// **'{score}%'**
  String reconstructionQualityScore(int score);

  /// No description provided for @reconstructionQualityLabel.
  ///
  /// In en, this message translates to:
  /// **'Overall quality'**
  String get reconstructionQualityLabel;

  /// No description provided for @reconstructionQualityGreen.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reconstructionQualityGreen;

  /// No description provided for @reconstructionQualityAmber.
  ///
  /// In en, this message translates to:
  /// **'Some limitations'**
  String get reconstructionQualityAmber;

  /// No description provided for @reconstructionEstimatedMinutes.
  ///
  /// In en, this message translates to:
  /// **'~{minutes} min'**
  String reconstructionEstimatedMinutes(int minutes);

  /// No description provided for @reconstructionEstimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Estimated processing time'**
  String get reconstructionEstimatedTime;

  /// No description provided for @reconstructionProcessTitle.
  ///
  /// In en, this message translates to:
  /// **'What happens next?'**
  String get reconstructionProcessTitle;

  /// No description provided for @reconstructionProcessImages.
  ///
  /// In en, this message translates to:
  /// **'Selected images'**
  String get reconstructionProcessImages;

  /// No description provided for @reconstructionProcessCloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud processing'**
  String get reconstructionProcessCloud;

  /// No description provided for @reconstructionProcessModel.
  ///
  /// In en, this message translates to:
  /// **'3D model'**
  String get reconstructionProcessModel;

  /// No description provided for @reconstructionProcessBody.
  ///
  /// In en, this message translates to:
  /// **'Your qualified images will be used to create the 3D model.'**
  String get reconstructionProcessBody;

  /// No description provided for @reconstructionResourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get reconstructionResourceTitle;

  /// No description provided for @reconstructionResourceBody.
  ///
  /// In en, this message translates to:
  /// **'3D reconstruction uses processing resources and may take several minutes. Once started, it cannot be easily cancelled. Now is the easiest time to go back and check your images.'**
  String get reconstructionResourceBody;

  /// No description provided for @reconstructionAmberReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Previously acknowledged warning'**
  String get reconstructionAmberReminderTitle;

  /// No description provided for @reconstructionAmberReminderBody.
  ///
  /// In en, this message translates to:
  /// **'You have already acknowledged the quality warning. This image set still has some limitations, so the model may lose some detail.'**
  String get reconstructionAmberReminderBody;

  /// No description provided for @reconstructionStart.
  ///
  /// In en, this message translates to:
  /// **'Start reconstruction'**
  String get reconstructionStart;

  /// No description provided for @reconstructionBackToReview.
  ///
  /// In en, this message translates to:
  /// **'Back to image review'**
  String get reconstructionBackToReview;

  /// No description provided for @reconstructionSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting…'**
  String get reconstructionSubmitting;

  /// No description provided for @reconstructionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get reconstructionSubmitted;

  /// No description provided for @reconstructionSubmissionError.
  ///
  /// In en, this message translates to:
  /// **'Could not submit. Please try starting reconstruction again.'**
  String get reconstructionSubmissionError;

  /// No description provided for @modelConfirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Create 3D Model from Photos'**
  String get modelConfirmationTitle;

  /// No description provided for @modelConfirmationAiTooltip.
  ///
  /// In en, this message translates to:
  /// **'3D Forge AI assistant'**
  String get modelConfirmationAiTooltip;

  /// No description provided for @modelConfirmationOriginalPhoto.
  ///
  /// In en, this message translates to:
  /// **'Original photo'**
  String get modelConfirmationOriginalPhoto;

  /// No description provided for @modelConfirmationKeepsakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Keepsake doll'**
  String get modelConfirmationKeepsakePhoto;

  /// No description provided for @modelConfirmationConsentBadge.
  ///
  /// In en, this message translates to:
  /// **'100% consented'**
  String get modelConfirmationConsentBadge;

  /// No description provided for @modelConfirmationAllPhotos.
  ///
  /// In en, this message translates to:
  /// **'All captured photos'**
  String get modelConfirmationAllPhotos;

  /// No description provided for @modelConfirmationHeader.
  ///
  /// In en, this message translates to:
  /// **'Create a 3D model from photos ✨'**
  String get modelConfirmationHeader;

  /// No description provided for @modelConfirmationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We received {count} photos to create a vivid 3D image.'**
  String modelConfirmationSubtitle(int count);

  /// No description provided for @modelConfirmationInfo.
  ///
  /// In en, this message translates to:
  /// **'Automatically convert photos into a complete 3D model in just a few taps'**
  String get modelConfirmationInfo;

  /// No description provided for @modelConfirmationUploadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Uploaded photos'**
  String get modelConfirmationUploadedTitle;

  /// No description provided for @modelConfirmationUploadedValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sharp photos yet} other{{count} sharp photos}}'**
  String modelConfirmationUploadedValue(int count);

  /// No description provided for @modelConfirmationGeneratedTitle.
  ///
  /// In en, this message translates to:
  /// **'3D model output'**
  String get modelConfirmationGeneratedTitle;

  /// No description provided for @modelConfirmationGeneratedValue.
  ///
  /// In en, this message translates to:
  /// **'Sharp 3D model'**
  String get modelConfirmationGeneratedValue;

  /// No description provided for @modelConfirmationGenerating.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get modelConfirmationGenerating;

  /// No description provided for @modelConfirmationFormatTitle.
  ///
  /// In en, this message translates to:
  /// **'File format'**
  String get modelConfirmationFormatTitle;

  /// No description provided for @modelConfirmationFormatValue.
  ///
  /// In en, this message translates to:
  /// **'.GLB / 3D ready (.STL)'**
  String get modelConfirmationFormatValue;

  /// No description provided for @modelConfirmationFormatBadge.
  ///
  /// In en, this message translates to:
  /// **'3D standard'**
  String get modelConfirmationFormatBadge;

  /// No description provided for @modelConfirmationWarning.
  ///
  /// In en, this message translates to:
  /// **'No photos are ready yet. Go back and capture at least one photo before creating the 3D model.'**
  String get modelConfirmationWarning;

  /// No description provided for @modelConfirmationCta.
  ///
  /// In en, this message translates to:
  /// **'Create 3D Model now'**
  String get modelConfirmationCta;

  /// No description provided for @modelConfirmationSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Creating model...'**
  String get modelConfirmationSubmitting;

  /// No description provided for @modelConfirmationEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimated time: 1–2 minutes'**
  String get modelConfirmationEstimate;

  /// No description provided for @modelConfirmationError.
  ///
  /// In en, this message translates to:
  /// **'Could not create the 3D model. Please try again.'**
  String get modelConfirmationError;

  /// No description provided for @processingSimulated.
  ///
  /// In en, this message translates to:
  /// **'Simulated progress — demo only'**
  String get processingSimulated;

  /// No description provided for @processingTakesTime.
  ///
  /// In en, this message translates to:
  /// **'Reconstruction may take some time. The current stage is shown below.'**
  String get processingTakesTime;

  /// No description provided for @processingDemoCompleted.
  ///
  /// In en, this message translates to:
  /// **'Simulation completed'**
  String get processingDemoCompleted;

  /// No description provided for @processingDemoCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'This demo has finished. No 3D model was created.'**
  String get processingDemoCompleteBody;

  /// No description provided for @processingDemoFailure.
  ///
  /// In en, this message translates to:
  /// **'The simulation stopped while generating details. You can retry the demo.'**
  String get processingDemoFailure;

  /// No description provided for @processingSourceFailure.
  ///
  /// In en, this message translates to:
  /// **'Progress updates could not be received.'**
  String get processingSourceFailure;

  /// No description provided for @processingStoppedHere.
  ///
  /// In en, this message translates to:
  /// **'Stopped at this stage'**
  String get processingStoppedHere;

  /// No description provided for @processingReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get processingReturn;

  /// No description provided for @processingObservationAuth.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Sign in again to check progress.'**
  String get processingObservationAuth;

  /// No description provided for @processingObservationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This reconstruction job is unavailable.'**
  String get processingObservationUnavailable;

  /// No description provided for @processingObservationContract.
  ///
  /// In en, this message translates to:
  /// **'Progress could not be read. Please try again.'**
  String get processingObservationContract;

  /// No description provided for @processingObservationTransient.
  ///
  /// In en, this message translates to:
  /// **'Progress is temporarily unavailable. Retrying automatically.'**
  String get processingObservationTransient;

  /// No description provided for @processingObservationExhausted.
  ///
  /// In en, this message translates to:
  /// **'Progress updates have stopped after repeated connection problems. Retry to check again.'**
  String get processingObservationExhausted;

  /// No description provided for @processingObservationLoading.
  ///
  /// In en, this message translates to:
  /// **'Retrieving reconstruction status'**
  String get processingObservationLoading;

  /// No description provided for @processingObservationLoadingBody.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we check the reconstruction job.'**
  String get processingObservationLoadingBody;

  /// No description provided for @processingQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get processingQueued;

  /// No description provided for @processingQueuedBody.
  ///
  /// In en, this message translates to:
  /// **'Waiting for reconstruction.'**
  String get processingQueuedBody;

  /// No description provided for @processingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get processingCancelled;

  /// No description provided for @processingCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'Reconstruction was cancelled.'**
  String get processingCancelledBody;

  /// No description provided for @processingBackendReal.
  ///
  /// In en, this message translates to:
  /// **'Backend processing'**
  String get processingBackendReal;

  /// No description provided for @processingProvenanceUnknown.
  ///
  /// In en, this message translates to:
  /// **'Processing mode not yet known'**
  String get processingProvenanceUnknown;

  /// No description provided for @processingBackendDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading reconstruction input'**
  String get processingBackendDownloading;

  /// No description provided for @processingBackendPreprocessing.
  ///
  /// In en, this message translates to:
  /// **'Preprocessing reconstruction input'**
  String get processingBackendPreprocessing;

  /// No description provided for @processingBackendShapeGeneration.
  ///
  /// In en, this message translates to:
  /// **'Generating shape'**
  String get processingBackendShapeGeneration;

  /// No description provided for @processingBackendTexturing.
  ///
  /// In en, this message translates to:
  /// **'Applying textures'**
  String get processingBackendTexturing;

  /// No description provided for @processingBackendValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating reconstruction'**
  String get processingBackendValidating;

  /// No description provided for @processingBackendExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting reconstruction'**
  String get processingBackendExporting;

  /// No description provided for @processingBackendUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading reconstruction output'**
  String get processingBackendUploading;

  /// No description provided for @processingProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Creating 3D model...'**
  String get processingProgressTitle;

  /// No description provided for @processingProgressSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing angles and details to build a vivid 3D model.'**
  String get processingProgressSubtitle;

  /// No description provided for @processingProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'PROGRESS'**
  String get processingProgressLabel;

  /// No description provided for @processingHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'PROCESSING LOG'**
  String get processingHistoryTitle;

  /// No description provided for @processingTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tip from Memento3D'**
  String get processingTipTitle;

  /// No description provided for @processingTipBody.
  ///
  /// In en, this message translates to:
  /// **'Capture extra angles to make the 3D model more accurate.'**
  String get processingTipBody;

  /// No description provided for @processingRunInBackground.
  ///
  /// In en, this message translates to:
  /// **'Run in background & Get notified'**
  String get processingRunInBackground;

  /// No description provided for @processingBackgroundAck.
  ///
  /// In en, this message translates to:
  /// **'You will be notified when processing completes.'**
  String get processingBackgroundAck;

  /// No description provided for @processingReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get processingReconnecting;

  /// No description provided for @processingEtaUnknown.
  ///
  /// In en, this message translates to:
  /// **'Estimating remaining time...'**
  String get processingEtaUnknown;

  /// No description provided for @processingEtaShort.
  ///
  /// In en, this message translates to:
  /// **'almost done'**
  String get processingEtaShort;

  /// No description provided for @processingEtaMinutes.
  ///
  /// In en, this message translates to:
  /// **'about {minutes} minutes left'**
  String processingEtaMinutes(int minutes);

  /// No description provided for @jobStageQueued.
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get jobStageQueued;

  /// No description provided for @jobStageDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading input image'**
  String get jobStageDownloading;

  /// No description provided for @jobStagePreprocessing.
  ///
  /// In en, this message translates to:
  /// **'Preprocessing'**
  String get jobStagePreprocessing;

  /// No description provided for @jobStageShapeGeneration.
  ///
  /// In en, this message translates to:
  /// **'Generating 3D shape'**
  String get jobStageShapeGeneration;

  /// No description provided for @jobStageTexturing.
  ///
  /// In en, this message translates to:
  /// **'Texturing'**
  String get jobStageTexturing;

  /// No description provided for @jobStageValidating.
  ///
  /// In en, this message translates to:
  /// **'Validating'**
  String get jobStageValidating;

  /// No description provided for @jobStageExporting.
  ///
  /// In en, this message translates to:
  /// **'Exporting'**
  String get jobStageExporting;

  /// No description provided for @jobStageUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading model'**
  String get jobStageUploading;

  /// No description provided for @jobStageDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get jobStageDone;

  /// No description provided for @processingPhaseStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step}/{total}: {label}'**
  String processingPhaseStep(int step, int total, String label);

  /// No description provided for @processingPhaseAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing input image'**
  String get processingPhaseAnalyzing;

  /// No description provided for @processingPhaseModeling.
  ///
  /// In en, this message translates to:
  /// **'Building shape & mesh'**
  String get processingPhaseModeling;

  /// No description provided for @processingPhaseFinishing.
  ///
  /// In en, this message translates to:
  /// **'Texturing & finalizing model'**
  String get processingPhaseFinishing;

  /// No description provided for @jobFailedHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Create 3D Model'**
  String get jobFailedHeaderTitle;

  /// No description provided for @jobFailedStatusBadge.
  ///
  /// In en, this message translates to:
  /// **'Status: Failed'**
  String get jobFailedStatusBadge;

  /// No description provided for @jobFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the 3D model'**
  String get jobFailedTitle;

  /// No description provided for @jobFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Some reconstruction steps encountered an issue. Don\'t worry, your captures are safe.'**
  String get jobFailedSubtitle;

  /// No description provided for @jobFailedCardTitle.
  ///
  /// In en, this message translates to:
  /// **'What happened?'**
  String get jobFailedCardTitle;

  /// No description provided for @jobRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry 3D generation'**
  String get jobRetry;

  /// No description provided for @jobRetrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying...'**
  String get jobRetrying;

  /// No description provided for @jobDashboard.
  ///
  /// In en, this message translates to:
  /// **'Back to Dashboard'**
  String get jobDashboard;

  /// No description provided for @jobRetryLimit.
  ///
  /// In en, this message translates to:
  /// **'You have exceeded the allowed retry attempts. Please contact support or create a new scan.'**
  String get jobRetryLimit;

  /// No description provided for @jobRetryFailedHint.
  ///
  /// In en, this message translates to:
  /// **'Retry is unavailable right now. Check your connection and try again.'**
  String get jobRetryFailedHint;

  /// No description provided for @jobFailedIllustrationTag.
  ///
  /// In en, this message translates to:
  /// **'3D AI Engine'**
  String get jobFailedIllustrationTag;

  /// No description provided for @modelViewerTitle.
  ///
  /// In en, this message translates to:
  /// **'3D model'**
  String get modelViewerTitle;

  /// No description provided for @modelViewerModelReady.
  ///
  /// In en, this message translates to:
  /// **'Model ready'**
  String get modelViewerModelReady;

  /// No description provided for @modelViewerReadyExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your model is ready to explore. Rotate it to see it from every angle.'**
  String get modelViewerReadyExplanation;

  /// No description provided for @modelViewerPendingExplanation.
  ///
  /// In en, this message translates to:
  /// **'Your model is being prepared. You can explore it when it is ready.'**
  String get modelViewerPendingExplanation;

  /// No description provided for @modelViewerUnavailableExplanation.
  ///
  /// In en, this message translates to:
  /// **'A model is not available for this item yet.'**
  String get modelViewerUnavailableExplanation;

  /// No description provided for @modelViewerReference.
  ///
  /// In en, this message translates to:
  /// **'Reference · {code}'**
  String modelViewerReference(String code);

  /// No description provided for @modelViewerFormat.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get modelViewerFormat;

  /// No description provided for @modelViewerFormatGlb.
  ///
  /// In en, this message translates to:
  /// **'GLB'**
  String get modelViewerFormatGlb;

  /// No description provided for @modelViewerStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get modelViewerStatus;

  /// No description provided for @modelViewerDetail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get modelViewerDetail;

  /// No description provided for @modelViewerDetailHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get modelViewerDetailHigh;

  /// No description provided for @modelViewerPercentage.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String modelViewerPercentage(int value);

  /// No description provided for @modelViewerContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get modelViewerContinue;

  /// No description provided for @modelViewerPreviewName.
  ///
  /// In en, this message translates to:
  /// **'Little robot · Development preview'**
  String get modelViewerPreviewName;

  /// No description provided for @modelViewerPreviewAction.
  ///
  /// In en, this message translates to:
  /// **'Preview only — no next screen is connected.'**
  String get modelViewerPreviewAction;

  /// No description provided for @modelViewerPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'3D viewer preview'**
  String get modelViewerPreviewTitle;

  /// No description provided for @modelViewerInitializing.
  ///
  /// In en, this message translates to:
  /// **'Starting 3D viewer…'**
  String get modelViewerInitializing;

  /// No description provided for @modelViewerReady.
  ///
  /// In en, this message translates to:
  /// **'3D viewer ready'**
  String get modelViewerReady;

  /// No description provided for @modelViewerShaded.
  ///
  /// In en, this message translates to:
  /// **'Shaded'**
  String get modelViewerShaded;

  /// No description provided for @modelViewerWireframe.
  ///
  /// In en, this message translates to:
  /// **'Wireframe'**
  String get modelViewerWireframe;

  /// No description provided for @modelViewerGrid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get modelViewerGrid;

  /// No description provided for @modelViewerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset View'**
  String get modelViewerReset;

  /// No description provided for @modelViewerInteractionHint.
  ///
  /// In en, this message translates to:
  /// **'Rotate • Zoom • Pan'**
  String get modelViewerInteractionHint;

  /// No description provided for @modelViewerLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading 3D model…'**
  String get modelViewerLoading;

  /// No description provided for @modelViewerLoaded.
  ///
  /// In en, this message translates to:
  /// **'3D model loaded'**
  String get modelViewerLoaded;

  /// No description provided for @modelViewerLoadError.
  ///
  /// In en, this message translates to:
  /// **'The 3D model could not be loaded.'**
  String get modelViewerLoadError;

  /// No description provided for @modelViewerInitializationError.
  ///
  /// In en, this message translates to:
  /// **'The 3D viewer could not start. Close this view and try again.'**
  String get modelViewerInitializationError;

  /// No description provided for @modelViewerScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'3D Model Viewer'**
  String get modelViewerScreenTitle;

  /// No description provided for @modelViewerFetchingOutputs.
  ///
  /// In en, this message translates to:
  /// **'Fetching model information…'**
  String get modelViewerFetchingOutputs;

  /// No description provided for @modelViewerDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading 3D model…'**
  String get modelViewerDownloading;

  /// No description provided for @modelViewerNoPrimaryGlb.
  ///
  /// In en, this message translates to:
  /// **'No primary GLB model is available for this scan.'**
  String get modelViewerNoPrimaryGlb;

  /// No description provided for @modelViewerRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get modelViewerRetry;

  /// No description provided for @checkPrintabilityCta.
  ///
  /// In en, this message translates to:
  /// **'Check Printability'**
  String get checkPrintabilityCta;

  /// No description provided for @rateAndShareCta.
  ///
  /// In en, this message translates to:
  /// **'Rate & Share'**
  String get rateAndShareCta;

  /// No description provided for @orderPhysicalPrintCta.
  ///
  /// In en, this message translates to:
  /// **'Order a physical print'**
  String get orderPhysicalPrintCta;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
