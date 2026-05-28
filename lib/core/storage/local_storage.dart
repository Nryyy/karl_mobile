import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/documents/domain/document_models.dart';

/// Simple local storage helper using SharedPreferences.
/// Provides methods for saving settings and a JSON cache for documents.
class LocalStorage {
  static const _cachedDocumentsKey = 'karl_cached_documents_v1';
  static const _themeModeKey = 'karl_theme_mode_v1';
  static const _localeKey = 'karl_locale_v1';

  LocalStorage._();

  /// Save JSON string of documents to shared preferences.
  static Future<void> saveCachedDocumentsJson(String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedDocumentsKey, json);
    } catch (_) {}
  }

  /// Load cached documents from shared preferences and parse them.
  static Future<List<DocumentListItem>> loadCachedDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cachedDocumentsKey);
      if (json == null || json.isEmpty) return const <DocumentListItem>[];
      final decoded = jsonDecode(json);
      if (decoded is! List) return const <DocumentListItem>[];
      return decoded
          .map((e) => DocumentListItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (_) {
      return const <DocumentListItem>[];
    }
  }

  /// Save a simple string setting for theme mode (e.g. 'light'|'dark'|'system').
  static Future<void> saveThemeMode(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, value);
    } catch (_) {}
  }

  static Future<String?> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_themeModeKey);
    } catch (_) {
      return null;
    }
  }

  /// Save selected locale language code (e.g. 'en','uk','pl'). Empty = system.
  static Future<void> saveLocale(String? languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (languageCode == null || languageCode.isEmpty) {
        await prefs.remove(_localeKey);
      } else {
        await prefs.setString(_localeKey, languageCode);
      }
    } catch (_) {}
  }

  static Future<String?> loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_localeKey);
    } catch (_) {
      return null;
    }
  }
}
