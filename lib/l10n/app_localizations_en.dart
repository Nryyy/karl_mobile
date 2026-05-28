// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Karl';

  @override
  String get documents => 'Documents';

  @override
  String get myDocuments => 'My Documents';

  @override
  String get archive => 'Archive';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get settings => 'Settings';

  @override
  String get help => 'Help';

  @override
  String get upload => 'Upload';

  @override
  String get signOut => 'Sign out';

  @override
  String get language => 'Language';

  @override
  String get cachedDataBanner => 'Showing cached data (offline)';

  @override
  String get noDocuments => 'No documents found';

  @override
  String get searchHint => 'Search documents...';

  @override
  String get closeApp => 'Close app';

  @override
  String get firebaseInitError => 'Firebase initialization error';

  @override
  String get ok => 'OK';
}
