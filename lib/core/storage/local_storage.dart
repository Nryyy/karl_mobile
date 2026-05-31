import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/documents/domain/document_models.dart';

/// Simple local storage helper using SharedPreferences.
/// Provides methods for saving settings and a JSON cache for documents.
/// Includes TTL support and comprehensive error logging.
class LocalStorage {
  static const _cachedDocumentsKey = 'karl_cached_documents_v1';
  static const _cachedSentToMeDocumentsKey = 'karl_cached_sent_to_me_documents_v1';
  static const _cachedUsersKey = 'karl_cached_users_v1';
  static const _cachedCurrentUserKey = 'karl_cached_current_user_v1';
  static const _themeModeKey = 'karl_theme_mode_v1';
  static const _localeKey = 'karl_locale_v1';
  
  // TTL constants (in milliseconds)
  static const _documentsTtl = 5 * 60 * 1000; // 5 minutes
  static const _usersTtl = 30 * 60 * 1000; // 30 minutes
  static const _currentUserTtl = 60 * 60 * 1000; // 1 hour
  
  // Timestamp keys
  static const _documentsTimestampKey = 'karl_documents_timestamp_v1';
  static const _sentToMeDocumentsTimestampKey = 'karl_sent_to_me_documents_timestamp_v1';
  static const _usersTimestampKey = 'karl_users_timestamp_v1';
  static const _currentUserTimestampKey = 'karl_current_user_timestamp_v1';

  LocalStorage._();

  /// Save JSON string of documents to shared preferences with timestamp.
  static Future<void> saveCachedDocumentsJson(String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedDocumentsKey, json);
      await prefs.setString(_documentsTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
      developer.log('Documents cached successfully', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to cache documents: $e', name: 'karl.storage', error: e);
    }
  }

  /// Load cached documents from shared preferences and parse them.
  /// Returns empty list if cache is expired or invalid.
  static Future<List<DocumentListItem>> loadCachedDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cachedDocumentsKey);
      final timestampStr = prefs.getString(_documentsTimestampKey);
      
      if (json == null || json.isEmpty || timestampStr == null) {
        developer.log('No cached documents found', name: 'karl.storage');
        return const <DocumentListItem>[];
      }
      
      // Check TTL
      final timestamp = int.parse(timestampStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > _documentsTtl) {
        developer.log('Cached documents expired', name: 'karl.storage');
        await clearCachedDocuments();
        return const <DocumentListItem>[];
      }
      
      final decoded = jsonDecode(json);
      if (decoded is! List) {
        developer.log('Invalid cached documents format', name: 'karl.storage');
        return const <DocumentListItem>[];
      }
      
      final documents = decoded
          .map((e) => DocumentListItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
      
      developer.log('Loaded ${documents.length} cached documents', name: 'karl.storage');
      return documents;
    } catch (e) {
      developer.log('Failed to load cached documents: $e', name: 'karl.storage', error: e);
      return const <DocumentListItem>[];
    }
  }

  /// Save a simple string setting for theme mode (e.g. 'light'|'dark'|'system').
  static Future<void> saveThemeMode(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, value);
      developer.log('Theme mode saved: $value', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to save theme mode: $e', name: 'karl.storage', error: e);
    }
  }

  static Future<String?> loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_themeModeKey);
      developer.log('Theme mode loaded: $value', name: 'karl.storage');
      return value;
    } catch (e) {
      developer.log('Failed to load theme mode: $e', name: 'karl.storage', error: e);
      return null;
    }
  }

  /// Save selected locale language code (e.g. 'en','uk','pl'). Empty = system.
  static Future<void> saveLocale(String? languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (languageCode == null || languageCode.isEmpty) {
        await prefs.remove(_localeKey);
        developer.log('Locale removed', name: 'karl.storage');
      } else {
        await prefs.setString(_localeKey, languageCode);
        developer.log('Locale saved: $languageCode', name: 'karl.storage');
      }
    } catch (e) {
      developer.log('Failed to save locale: $e', name: 'karl.storage', error: e);
    }
  }

  static Future<String?> loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_localeKey);
      developer.log('Locale loaded: $value', name: 'karl.storage');
      return value;
    } catch (e) {
      developer.log('Failed to load locale: $e', name: 'karl.storage', error: e);
      return null;
    }
  }
  
  /// Clear cached documents.
  static Future<void> clearCachedDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedDocumentsKey);
      await prefs.remove(_documentsTimestampKey);
      developer.log('Cached documents cleared', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to clear cached documents: $e', name: 'karl.storage', error: e);
    }
  }
  
  /// Save sent-to-me documents with timestamp.
  static Future<void> saveCachedSentToMeDocumentsJson(String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedSentToMeDocumentsKey, json);
      await prefs.setString(_sentToMeDocumentsTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
      developer.log('Sent-to-me documents cached successfully', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to cache sent-to-me documents: $e', name: 'karl.storage', error: e);
    }
  }
  
  /// Load cached sent-to-me documents.
  static Future<List<DocumentListItem>> loadCachedSentToMeDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cachedSentToMeDocumentsKey);
      final timestampStr = prefs.getString(_sentToMeDocumentsTimestampKey);
      
      if (json == null || json.isEmpty || timestampStr == null) {
        return const <DocumentListItem>[];
      }
      
      // Check TTL
      final timestamp = int.parse(timestampStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > _documentsTtl) {
        await clearCachedSentToMeDocuments();
        return const <DocumentListItem>[];
      }
      
      final decoded = jsonDecode(json);
      if (decoded is! List) {
        return const <DocumentListItem>[];
      }
      
      return decoded
          .map((e) => DocumentListItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      developer.log('Failed to load cached sent-to-me documents: $e', name: 'karl.storage', error: e);
      return const <DocumentListItem>[];
    }
  }
  
  /// Clear cached sent-to-me documents.
  static Future<void> clearCachedSentToMeDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedSentToMeDocumentsKey);
      await prefs.remove(_sentToMeDocumentsTimestampKey);
      developer.log('Cached sent-to-me documents cleared', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to clear cached sent-to-me documents: $e', name: 'karl.storage', error: e);
    }
  }
  
  /// Save users list with timestamp.
  static Future<void> saveCachedUsersJson(String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedUsersKey, json);
      await prefs.setString(_usersTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
      developer.log('Users cached successfully', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to cache users: $e', name: 'karl.storage', error: e);
    }
  }
  
  /// Load cached users list.
  static Future<List<UserProfile>> loadCachedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cachedUsersKey);
      final timestampStr = prefs.getString(_usersTimestampKey);
      
      if (json == null || json.isEmpty || timestampStr == null) {
        return const <UserProfile>[];
      }
      
      // Check TTL
      final timestamp = int.parse(timestampStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > _usersTtl) {
        await clearCachedUsers();
        return const <UserProfile>[];
      }
      
      final decoded = jsonDecode(json);
      if (decoded is! List) {
        return const <UserProfile>[];
      }
      
      return decoded
          .map((e) => UserProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    } catch (e) {
      developer.log('Failed to load cached users: $e', name: 'karl.storage', error: e);
      return const <UserProfile>[];
    }
  }
  
  /// Clear cached users.
  static Future<void> clearCachedUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedUsersKey);
      await prefs.remove(_usersTimestampKey);
      developer.log('Cached users cleared', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to clear cached users: $e', name: 'karl.storage', error: e);
    }
  }
  
  /// Save current user profile with timestamp.
  static Future<void> saveCachedCurrentUserJson(String json) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedCurrentUserKey, json);
      await prefs.setString(_currentUserTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
      developer.log('Current user cached successfully', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to cache current user: $e', name: 'karl.storage', error: e);
    }
  }
  
  /// Load cached current user profile.
  static Future<UserProfile?> loadCachedCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cachedCurrentUserKey);
      final timestampStr = prefs.getString(_currentUserTimestampKey);
      
      if (json == null || json.isEmpty || timestampStr == null) {
        return null;
      }
      
      // Check TTL
      final timestamp = int.parse(timestampStr);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - timestamp > _currentUserTtl) {
        await clearCachedCurrentUser();
        return null;
      }
      
      final decoded = jsonDecode(json);
      if (decoded is! Map) {
        return null;
      }
      
      return UserProfile.fromJson(Map<String, dynamic>.from(decoded as Map));
    } catch (e) {
      developer.log('Failed to load cached current user: $e', name: 'karl.storage', error: e);
      return null;
    }
  }
  
  /// Clear cached current user.
  static Future<void> clearCachedCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cachedCurrentUserKey);
      await prefs.remove(_currentUserTimestampKey);
      developer.log('Cached current user cleared', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to clear cached current user: $e', name: 'karl.storage', error: e);
    }
  }
  
  /// Clear all cached data.
  static Future<void> clearAllCache() async {
    try {
      await clearCachedDocuments();
      await clearCachedSentToMeDocuments();
      await clearCachedUsers();
      await clearCachedCurrentUser();
      developer.log('All cache cleared', name: 'karl.storage');
    } catch (e) {
      developer.log('Failed to clear all cache: $e', name: 'karl.storage', error: e);
    }
  }
}
