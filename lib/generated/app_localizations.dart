import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('en'), Locale('uk'), Locale('pl')];

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Karl',
      'documents': 'Documents',
      'myDocuments': 'My Documents',
      'archive': 'Archive',
      'dashboard': 'Dashboard',
      'settings': 'Settings',
      'help': 'Help',
      'upload': 'Upload',
      'signOut': 'Sign out',
      'language': 'Language',
      'cachedDataBanner': 'Showing cached data (offline)',
      'noDocuments': 'No documents found',
      'searchHint': 'Search documents...',
      'closeApp': 'Close app',
      'firebaseInitError': 'Firebase initialization error',
      'ok': 'OK',
      'refresh': 'Refresh'
    },
    'uk': {
      'appTitle': 'Karl',
      'documents': 'Документи',
      'myDocuments': 'Мої документи',
      'archive': 'Архів',
      'dashboard': 'Головна',
      'settings': 'Налаштування',
      'help': 'Допомога',
      'upload': 'Завантажити',
      'signOut': 'Вийти',
      'language': 'Мова',
      'cachedDataBanner': 'Показано кешовані дані (офлайн)',
      'noDocuments': 'Документи не знайдено',
      'searchHint': 'Пошук документів...',
      'closeApp': 'Закрити додаток',
      'firebaseInitError': 'Помилка ініціалізації Firebase',
      'ok': 'OK',
      'refresh': 'Оновити'
    },
    'pl': {
      'appTitle': 'Karl',
      'documents': 'Dokumenty',
      'myDocuments': 'Moje dokumenty',
      'archive': 'Archiwum',
      'dashboard': 'Panel',
      'settings': 'Ustawienia',
      'help': 'Pomoc',
      'upload': 'Prześlij',
      'signOut': 'Wyloguj',
      'language': 'Język',
      'cachedDataBanner': 'Wyświetlane dane z pamięci podręcznej (offline)',
      'noDocuments': 'Brak dokumentów',
      'searchHint': 'Szukaj dokumentów...',
      'closeApp': 'Zamknij aplikację',
      'firebaseInitError': 'Błąd inicjalizacji Firebase',
      'ok': 'OK',
      'refresh': 'Odśwież'
    }
  };

  String? _t(String key) => _localizedValues[locale.languageCode]?[key] ?? _localizedValues['en']?[key];

  String get appTitle => _t('appTitle') ?? '';
  String? get documents => _t('documents');
  String? get dashboard => _t('dashboard');
  String? get settings => _t('settings');
  String? get myDocuments => _t('myDocuments');
  String? get upload => _t('upload');
  String? get signOut => _t('signOut');
  String? get language => _t('language');
  String? get help => _t('help');
  String? get searchHint => _t('searchHint');
  String? get firebaseInitError => _t('firebaseInitError');
  String? get closeApp => _t('closeApp');
  String? get ok => _t('ok');
  String? get refresh => _t('refresh');
  String? get loginTitle => _t('loginTitle');
  String? get loginSubtitle => _t('loginSubtitle');
  String? get feature1Title => _t('feature1_title');
  String? get feature1Desc => _t('feature1_desc');
  String? get feature2Title => _t('feature2_title');
  String? get feature2Desc => _t('feature2_desc');
  String? get feature3Title => _t('feature3_title');
  String? get feature3Desc => _t('feature3_desc');
  String? get feature4Title => _t('feature4_title');
  String? get feature4Desc => _t('feature4_desc');
  String? get newUser => _t('newUser');
  String? get createAccountSubtitle => _t('createAccountSubtitle');
  String? get register => _t('register');
  String? get privacy => _t('privacy');
  String? get terms => _t('terms');
  String? get footerHelp => _t('footerHelp');
  String? get signInError => _t('signInError');
  String? get googleSignInError => _t('googleSignInError');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any((l) => l.languageCode == locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => Future.value(AppLocalizations(locale));

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
