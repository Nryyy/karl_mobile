// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'Karl';

  @override
  String get documents => 'Документи';

  @override
  String get myDocuments => 'Мої документи';

  @override
  String get archive => 'Архів';

  @override
  String get dashboard => 'Головна';

  @override
  String get settings => 'Налаштування';

  @override
  String get help => 'Допомога';

  @override
  String get upload => 'Завантажити';

  @override
  String get signOut => 'Вийти';

  @override
  String get language => 'Мова';

  @override
  String get cachedDataBanner => 'Показано кешовані дані (офлайн)';

  @override
  String get noDocuments => 'Документи не знайдено';

  @override
  String get searchHint => 'Пошук документів...';

  @override
  String get closeApp => 'Закрити додаток';

  @override
  String get firebaseInitError => 'Помилка ініціалізації Firebase';

  @override
  String get ok => 'OK';
}
