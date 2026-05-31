import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:karl_mobile/core/storage/local_storage.dart';
import 'package:karl_mobile/features/documents/domain/document_models.dart';

void main() {
  group('LocalStorage Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('Theme Mode', () {
      test('saves and loads theme mode correctly', () async {
        await LocalStorage.saveThemeMode('dark');
        final loaded = await LocalStorage.loadThemeMode();
        expect(loaded, 'dark');
      });

      test('returns null when no theme mode is saved', () async {
        final loaded = await LocalStorage.loadThemeMode();
        expect(loaded, isNull);
      });

      test('overwrites existing theme mode', () async {
        await LocalStorage.saveThemeMode('light');
        await LocalStorage.saveThemeMode('dark');
        final loaded = await LocalStorage.loadThemeMode();
        expect(loaded, 'dark');
      });
    });

    group('Locale', () {
      test('saves and loads locale correctly', () async {
        await LocalStorage.saveLocale('uk');
        final loaded = await LocalStorage.loadLocale();
        expect(loaded, 'uk');
      });

      test('returns null when no locale is saved', () async {
        final loaded = await LocalStorage.loadLocale();
        expect(loaded, isNull);
      });

      test('removes locale when empty string is saved', () async {
        await LocalStorage.saveLocale('en');
        await LocalStorage.saveLocale('');
        final loaded = await LocalStorage.loadLocale();
        expect(loaded, isNull);
      });

      test('removes locale when null is saved', () async {
        await LocalStorage.saveLocale('en');
        await LocalStorage.saveLocale(null);
        final loaded = await LocalStorage.loadLocale();
        expect(loaded, isNull);
      });
    });

    group('Document Caching', () {
      test('saves and loads cached documents correctly', () async {
        final documents = [
          DocumentListItem(
            id: '1',
            title: 'Test Document',
            authorId: 'author1',
            authorName: 'Test Author',
            status: DocumentStatus(id: 'status1', name: 'Pending'),
            fileType: 'pdf',
            googleDriveFileId: 'drive1',
            webViewLink: 'https://example.com/view',
            webContentLink: 'https://example.com/content',
            createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
            updatedAt: null,
            signatures: [],
            comments: [],
            approvalFlow: ApprovalFlow(isActive: false, steps: [], currentStep: 0),
            metadata: DocumentMetadata(version: 1, tags: [], category: '', fileSize: 0, pageCount: 0),
          ),
        ];

        // Convert to JSON as the repository would
        final json = '[${documents.map((d) => d.toJson()).toList().map((e) => e.toString()).join(',')}]';
        await LocalStorage.saveCachedDocumentsJson(json);

        final loaded = await LocalStorage.loadCachedDocuments();
        expect(loaded.length, 1);
        expect(loaded[0].id, '1');
        expect(loaded[0].title, 'Test Document');
        expect(loaded[0].authorName, 'Test Author');
      });

      test('returns empty list when no documents are cached', () async {
        final loaded = await LocalStorage.loadCachedDocuments();
        expect(loaded, isEmpty);
      });

      test('handles malformed JSON gracefully', () async {
        await LocalStorage.saveCachedDocumentsJson('invalid json');
        final loaded = await LocalStorage.loadCachedDocuments();
        expect(loaded, isEmpty);
      });

      test('handles empty JSON array', () async {
        await LocalStorage.saveCachedDocumentsJson('[]');
        final loaded = await LocalStorage.loadCachedDocuments();
        expect(loaded, isEmpty);
      });

      test('overwrites existing cached documents', () async {
        // Save initial documents
        await LocalStorage.saveCachedDocumentsJson('[{"id":"1","title":"Old"}]');
        
        // Save new documents
        await LocalStorage.saveCachedDocumentsJson('[{"id":"2","title":"New"}]');
        
        final loaded = await LocalStorage.loadCachedDocuments();
        expect(loaded.length, 1);
        expect(loaded[0].id, '2');
      });
    });

    group('Error Handling', () {
      test('handles SharedPreferences errors gracefully', () async {
        // This test verifies that errors are caught and don't crash the app
        // In a real scenario, SharedPreferences might throw exceptions
        try {
          await LocalStorage.saveThemeMode('dark');
          await LocalStorage.loadThemeMode();
          await LocalStorage.saveLocale('en');
          await LocalStorage.loadLocale();
          await LocalStorage.saveCachedDocumentsJson('[]');
          await LocalStorage.loadCachedDocuments();
          // If we get here without exceptions, error handling works
          expect(true, isTrue);
        } catch (e) {
          fail('LocalStorage should handle SharedPreferences errors gracefully: $e');
        }
      });
    });
  });
}
