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
/// import 'generated/app_localizations.dart';
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

  /// No description provided for @approvalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No documents for approval'**
  String get approvalsEmptyTitle;

  /// No description provided for @approvalsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When someone sends you a document to sign, it will appear here.'**
  String get approvalsEmptySubtitle;

  /// No description provided for @archiveEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive is empty'**
  String get archiveEmptyTitle;

  /// No description provided for @archiveEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Archived documents will appear here'**
  String get archiveEmptySubtitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access the platform'**
  String get loginSubtitle;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Intelligent document circulation platform'**
  String get appTagline;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

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

  /// No description provided for @newDocument.
  ///
  /// In en, this message translates to:
  /// **'New document'**
  String get newDocument;

  /// No description provided for @loadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Loading documents...'**
  String get loadingDocuments;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @documentSigned.
  ///
  /// In en, this message translates to:
  /// **'Document signed'**
  String get documentSigned;

  /// No description provided for @documentRejected.
  ///
  /// In en, this message translates to:
  /// **'Document rejected'**
  String get documentRejected;

  /// No description provided for @signDocument.
  ///
  /// In en, this message translates to:
  /// **'Sign'**
  String get signDocument;

  /// No description provided for @rejectDocument.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectDocument;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @approvals.
  ///
  /// In en, this message translates to:
  /// **'Approvals'**
  String get approvals;

  /// No description provided for @documentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Document not found.'**
  String get documentNotFound;

  /// No description provided for @signDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign document'**
  String get signDocumentTitle;

  /// No description provided for @rejectDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Reject document'**
  String get rejectDocumentTitle;

  /// No description provided for @rejectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for rejection (optional):'**
  String get rejectPrompt;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @viewDocument.
  ///
  /// In en, this message translates to:
  /// **'View document'**
  String get viewDocument;

  /// No description provided for @signConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you confirm approval of this document? This action cannot be undone.'**
  String get signConfirm;

  /// No description provided for @rejectHint.
  ///
  /// In en, this message translates to:
  /// **'Reason for rejection...'**
  String get rejectHint;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @authorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Author:'**
  String get authorPrefix;

  /// No description provided for @statusPrefix.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get statusPrefix;

  /// No description provided for @chooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose an action:'**
  String get chooseAction;

  /// No description provided for @commentLabel.
  ///
  /// In en, this message translates to:
  /// **'Comment (optional)'**
  String get commentLabel;

  /// No description provided for @signOutError.
  ///
  /// In en, this message translates to:
  /// **'Unable to sign out. Please try again.'**
  String get signOutError;

  /// No description provided for @repositoryNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Repository not available.'**
  String get repositoryNotAvailable;

  /// No description provided for @archiveDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive document?'**
  String get archiveDocumentTitle;

  /// No description provided for @archiveDocumentContent.
  ///
  /// In en, this message translates to:
  /// **'The document will be moved to the archive.'**
  String get archiveDocumentContent;

  /// No description provided for @archiveCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get archiveCancel;

  /// No description provided for @archiveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveConfirm;

  /// No description provided for @archiveDone.
  ///
  /// In en, this message translates to:
  /// **'Document archived.'**
  String get archiveDone;

  /// No description provided for @archiveCancelled.
  ///
  /// In en, this message translates to:
  /// **'Archive cancelled.'**
  String get archiveCancelled;

  /// No description provided for @restoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to restore document.'**
  String get restoreFailed;

  /// No description provided for @archiveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to archive document.'**
  String get archiveFailed;

  /// No description provided for @deleteOnlyFromArchive.
  ///
  /// In en, this message translates to:
  /// **'Deletion allowed only from the archive.'**
  String get deleteOnlyFromArchive;

  /// No description provided for @deleteDocumentTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete document?'**
  String get deleteDocumentTitle;

  /// No description provided for @deleteDocumentContent.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Are you sure?'**
  String get deleteDocumentContent;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteConfirm;

  /// No description provided for @deleteDone.
  ///
  /// In en, this message translates to:
  /// **'Document deleted.'**
  String get deleteDone;

  /// No description provided for @deleteCancelled.
  ///
  /// In en, this message translates to:
  /// **'Deletion cancelled.'**
  String get deleteCancelled;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete document.'**
  String get deleteFailed;

  /// No description provided for @restoreDone.
  ///
  /// In en, this message translates to:
  /// **'Document restored.'**
  String get restoreDone;

  /// No description provided for @untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get untitled;

  /// No description provided for @chooseFileType.
  ///
  /// In en, this message translates to:
  /// **'Choose file type'**
  String get chooseFileType;

  /// No description provided for @chooseApprover.
  ///
  /// In en, this message translates to:
  /// **'Choose approver'**
  String get chooseApprover;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @statusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statusWaiting;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get statusInProgress;

  /// No description provided for @statusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statusApproved;

  /// No description provided for @statusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get statusRejected;

  /// No description provided for @selectAndUpload.
  ///
  /// In en, this message translates to:
  /// **'Select and upload file'**
  String get selectAndUpload;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload file'**
  String get uploadFile;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @noDocumentsDescription.
  ///
  /// In en, this message translates to:
  /// **'API did not return any documents yet.'**
  String get noDocumentsDescription;

  /// No description provided for @failedToLoadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Failed to load documents.'**
  String get failedToLoadDocuments;

  /// No description provided for @googleDrive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get googleDrive;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @googleDriveDescription.
  ///
  /// In en, this message translates to:
  /// **'Files are stored on Google Drive'**
  String get googleDriveDescription;

  /// No description provided for @fileUploaded.
  ///
  /// In en, this message translates to:
  /// **'File uploaded'**
  String get fileUploaded;

  /// No description provided for @settingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Theme, language, preferences'**
  String get settingsSubtitle;

  /// No description provided for @unknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown author'**
  String get unknownAuthor;

  /// No description provided for @notSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// No description provided for @typePrefix.
  ///
  /// In en, this message translates to:
  /// **'Type:'**
  String get typePrefix;

  /// No description provided for @createdPrefix.
  ///
  /// In en, this message translates to:
  /// **'Created:'**
  String get createdPrefix;

  /// No description provided for @greetingPrefix.
  ///
  /// In en, this message translates to:
  /// **'Welcome,'**
  String get greetingPrefix;

  /// No description provided for @greetingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what\'s happening with your documents today'**
  String get greetingSubtitle;

  /// No description provided for @statsWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get statsWaiting;

  /// No description provided for @statsApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get statsApproved;

  /// No description provided for @statsLast7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get statsLast7Days;

  /// No description provided for @statsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statsTotal;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick actions'**
  String get quickActions;

  /// No description provided for @activityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityTitle;

  /// No description provided for @activitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Latest notifications'**
  String get activitySubtitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need a hint?'**
  String get helpTitle;

  /// No description provided for @helpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Our AI assistant can help you understand system features'**
  String get helpSubtitle;

  /// No description provided for @tryDifferentQuery.
  ///
  /// In en, this message translates to:
  /// **'Try a different query or clear filters.'**
  String get tryDifferentQuery;
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
