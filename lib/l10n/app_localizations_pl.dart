// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Karl';

  @override
  String get documents => 'Dokumenty';

  @override
  String get myDocuments => 'Moje dokumenty';

  @override
  String get archive => 'Archiwum';

  @override
  String get dashboard => 'Panel';

  @override
  String get settings => 'Ustawienia';

  @override
  String get help => 'Pomoc';

  @override
  String get upload => 'Prześlij';

  @override
  String get signOut => 'Wyloguj';

  @override
  String get language => 'Język';

  @override
  String get cachedDataBanner => 'Wyświetlane dane z pamięci podręcznej (offline)';

  @override
  String get noDocuments => 'Brak dokumentów';

  @override
  String get searchHint => 'Szukaj dokumentów...';

  @override
  String get closeApp => 'Zamknij aplikację';

  @override
  String get firebaseInitError => 'Błąd inicjalizacji Firebase';

  @override
  String get ok => 'OK';
}
