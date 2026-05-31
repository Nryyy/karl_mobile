import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_uk.dart';

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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
    Locale('uk')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Karl'**
  String get appTitle;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @myDocuments.
  ///
  /// In en, this message translates to:
  /// **'My Documents'**
  String get myDocuments;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageUkrainian.
  ///
  /// In en, this message translates to:
  /// **'Ukrainian'**
  String get languageUkrainian;

  /// No description provided for @languagePolish.
  ///
  /// In en, this message translates to:
  /// **'Polish'**
  String get languagePolish;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutApp;

  /// No description provided for @cachedDataBanner.
  ///
  /// In en, this message translates to:
  /// **'Showing cached data (offline)'**
  String get cachedDataBanner;

  /// No description provided for @adminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin panel'**
  String get adminPanel;

  /// No description provided for @tooltipDashboard.
  ///
  /// In en, this message translates to:
  /// **'Home page'**
  String get tooltipDashboard;

  /// No description provided for @tooltipMyDocuments.
  ///
  /// In en, this message translates to:
  /// **'All your documents'**
  String get tooltipMyDocuments;

  /// No description provided for @tooltipArchive.
  ///
  /// In en, this message translates to:
  /// **'Archived documents'**
  String get tooltipArchive;

  /// No description provided for @tooltipAdminPanel.
  ///
  /// In en, this message translates to:
  /// **'Admin panel (admins only)'**
  String get tooltipAdminPanel;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile settings'**
  String get tooltipSettings;

  /// No description provided for @expandSidebar.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expandSidebar;

  /// No description provided for @collapseSidebar.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapseSidebar;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @templatesDescription.
  ///
  /// In en, this message translates to:
  /// **'Here you can store templates for your documents.'**
  String get templatesDescription;

  /// No description provided for @helpDescription.
  ///
  /// In en, this message translates to:
  /// **'Support, FAQ and useful resources.'**
  String get helpDescription;

  /// No description provided for @adminDescription.
  ///
  /// In en, this message translates to:
  /// **'Administration tools for the system.'**
  String get adminDescription;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @aiChatTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChatTitle;

  /// No description provided for @typeMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessageHint;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get noDocuments;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search documents...'**
  String get searchHint;

  /// No description provided for @closeApp.
  ///
  /// In en, this message translates to:
  /// **'Close app'**
  String get closeApp;

  /// No description provided for @firebaseInitError.
  ///
  /// In en, this message translates to:
  /// **'Firebase initialization error'**
  String get firebaseInitError;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error. Check logs.'**
  String get unknownError;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access the platform'**
  String get loginSubtitle;

  /// No description provided for @feature1_title.
  ///
  /// In en, this message translates to:
  /// **'Document management'**
  String get feature1_title;

  /// No description provided for @feature1_desc.
  ///
  /// In en, this message translates to:
  /// **'Store and organize all documents in one place'**
  String get feature1_desc;

  /// No description provided for @feature2_title.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get feature2_title;

  /// No description provided for @feature2_desc.
  ///
  /// In en, this message translates to:
  /// **'Smart document processing and workflow automation'**
  String get feature2_desc;

  /// No description provided for @feature3_title.
  ///
  /// In en, this message translates to:
  /// **'Teamwork'**
  String get feature3_title;

  /// No description provided for @feature3_desc.
  ///
  /// In en, this message translates to:
  /// **'Collaborate on documents with colleagues in real time'**
  String get feature3_desc;

  /// No description provided for @feature4_title.
  ///
  /// In en, this message translates to:
  /// **'Data security'**
  String get feature4_title;

  /// No description provided for @feature4_desc.
  ///
  /// In en, this message translates to:
  /// **'Enterprise-grade protection for your confidential documents'**
  String get feature4_desc;

  /// No description provided for @newUser.
  ///
  /// In en, this message translates to:
  /// **'New user?'**
  String get newUser;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account in minutes'**
  String get createAccountSubtitle;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get terms;

  /// No description provided for @footerHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get footerHelp;

  /// No description provided for @signInError.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in. Please try again.'**
  String get signInError;

  /// No description provided for @googleSignInError.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign in with Google.'**
  String get googleSignInError;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pl', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pl': return AppLocalizationsPl();
    case 'uk': return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
