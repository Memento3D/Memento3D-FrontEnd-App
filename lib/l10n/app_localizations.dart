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
