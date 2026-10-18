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

  /// No description provided for @paymentTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentTitle;

  /// No description provided for @paymentHeading.
  ///
  /// In en, this message translates to:
  /// **'Complete your order'**
  String get paymentHeading;

  /// No description provided for @paymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Review your order and choose a payment method'**
  String get paymentSubtitle;

  /// No description provided for @paymentProduct.
  ///
  /// In en, this message translates to:
  /// **'Personalized 3D model'**
  String get paymentProduct;

  /// No description provided for @paymentProductType.
  ///
  /// In en, this message translates to:
  /// **'Digital 3D model'**
  String get paymentProductType;

  /// No description provided for @paymentSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get paymentSubtotal;

  /// No description provided for @paymentFee.
  ///
  /// In en, this message translates to:
  /// **'Service fee'**
  String get paymentFee;

  /// No description provided for @paymentTotal.
  ///
  /// In en, this message translates to:
  /// **'Total payment'**
  String get paymentTotal;

  /// No description provided for @paymentMethods.
  ///
  /// In en, this message translates to:
  /// **'Payment methods'**
  String get paymentMethods;

  /// No description provided for @paymentSandbox.
  ///
  /// In en, this message translates to:
  /// **'Sandbox'**
  String get paymentSandbox;

  /// No description provided for @paymentMomoDescription.
  ///
  /// In en, this message translates to:
  /// **'Pay with MoMo wallet'**
  String get paymentMomoDescription;

  /// No description provided for @paymentZalopayDescription.
  ///
  /// In en, this message translates to:
  /// **'Pay quickly with ZaloPay'**
  String get paymentZalopayDescription;

  /// No description provided for @paymentVnpayDescription.
  ///
  /// In en, this message translates to:
  /// **'VNPAY QR or banking app'**
  String get paymentVnpayDescription;

  /// No description provided for @paymentSecurity.
  ///
  /// In en, this message translates to:
  /// **'Payments are securely processed by payment partners'**
  String get paymentSecurity;

  /// No description provided for @paymentPay.
  ///
  /// In en, this message translates to:
  /// **'Pay with {provider} • {amount}'**
  String paymentPay(String provider, String amount);

  /// No description provided for @paymentConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to {provider}'**
  String paymentConnecting(String provider);

  /// No description provided for @paymentProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Please keep the app open while the transaction is processing.'**
  String get paymentProcessingBody;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get paymentAmount;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get paymentMethod;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get paymentStatus;

  /// No description provided for @paymentProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get paymentProcessing;

  /// No description provided for @paymentCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel transaction'**
  String get paymentCancel;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment successful!'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessBody.
  ///
  /// In en, this message translates to:
  /// **'Payment for your 3D model order is complete.'**
  String get paymentSuccessBody;

  /// No description provided for @paymentReference.
  ///
  /// In en, this message translates to:
  /// **'Order reference'**
  String get paymentReference;

  /// No description provided for @paymentTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get paymentTime;

  /// No description provided for @paymentJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get paymentJustNow;

  /// No description provided for @paymentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get paymentSuccess;

  /// No description provided for @paymentViewOrder.
  ///
  /// In en, this message translates to:
  /// **'View order'**
  String get paymentViewOrder;

  /// No description provided for @paymentBack.
  ///
  /// In en, this message translates to:
  /// **'Back to payment'**
  String get paymentBack;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment unsuccessful'**
  String get paymentFailedTitle;

  /// No description provided for @paymentFailedBody.
  ///
  /// In en, this message translates to:
  /// **'The transaction could not be completed. You have not been charged.'**
  String get paymentFailedBody;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentFailed;

  /// No description provided for @paymentFailureNote.
  ///
  /// In en, this message translates to:
  /// **'Please retry or choose another payment method.'**
  String get paymentFailureNote;

  /// No description provided for @paymentRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get paymentRetry;

  /// No description provided for @paymentChooseOther.
  ///
  /// In en, this message translates to:
  /// **'Choose another method'**
  String get paymentChooseOther;

  /// No description provided for @paymentCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelledTitle;

  /// No description provided for @paymentCancelledBody.
  ///
  /// In en, this message translates to:
  /// **'The transaction was cancelled at your request. You have not been charged.'**
  String get paymentCancelledBody;

  /// No description provided for @paymentSelectedMethod.
  ///
  /// In en, this message translates to:
  /// **'Selected method'**
  String get paymentSelectedMethod;

  /// No description provided for @paymentCancelTime.
  ///
  /// In en, this message translates to:
  /// **'Cancellation time'**
  String get paymentCancelTime;

  /// No description provided for @paymentContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue payment'**
  String get paymentContinue;

  /// No description provided for @paymentHome.
  ///
  /// In en, this message translates to:
  /// **'Go home'**
  String get paymentHome;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping cart'**
  String get cartTitle;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Items you add will appear here.'**
  String get cartEmptyBody;

  /// No description provided for @cartCheckout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get cartCheckout;

  /// No description provided for @cartQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity: {count}'**
  String cartQuantity(int count);

  /// No description provided for @cartUnitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit price: {amount}'**
  String cartUnitPrice(String amount);

  /// No description provided for @cartSubtotal.
  ///
  /// In en, this message translates to:
  /// **'Subtotal: {amount}'**
  String cartSubtotal(String amount);

  /// No description provided for @cartTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String cartTotal(String amount);

  /// No description provided for @cartIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase quantity of {name}'**
  String cartIncrease(String name);

  /// No description provided for @cartDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease quantity of {name}'**
  String cartDecrease(String name);

  /// No description provided for @cartRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String cartRemove(String name);
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
