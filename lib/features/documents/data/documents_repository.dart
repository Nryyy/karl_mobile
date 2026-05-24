import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../domain/document_models.dart';

/// Abstraction for fetching documents from a data source.
abstract class DocumentsRepository {
  /// Loads the latest documents.
  Future<List<DocumentListItem>> fetchDocuments();
}

/// HTTP repository that reads documents from the API.
class HttpDocumentsRepository implements DocumentsRepository {
  /// Creates an HTTP documents repository.
  HttpDocumentsRepository({
    http.Client? client,
    this.baseUrl = _defaultBaseUrl,
    Future<String?> Function()? accessTokenProvider,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null,
       _accessTokenProvider = accessTokenProvider;

  static const String _defaultBaseUrl = 'https://localhost:7229';

  final http.Client _client;
  final bool _ownsClient;
  final Future<String?> Function()? _accessTokenProvider;

  /// Base URL of the documents API.
  final String baseUrl;

  /// Closes the underlying client when the repository owns it.
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<List<DocumentListItem>> fetchDocuments() async {
    final uri = Uri.parse('$baseUrl/api/Documents');
    final headers = <String, String>{'accept': 'application/json'};
    final accessToken = await _accessTokenProvider?.call();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['authorization'] = 'Bearer $accessToken';
    }

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == 401) {
      developer.log(
        'Documents API returned 401.',
        name: 'karl.documents',
        error: response.body,
      );
      throw DocumentsRepositoryException(
        'Сесія авторизації недійсна. Увійдіть ще раз.',
      );
    }

    if (response.statusCode != 200) {
      developer.log(
        'Documents API returned ${response.statusCode}.',
        name: 'karl.documents',
        error: response.body,
      );
      throw DocumentsRepositoryException(
        'Не вдалося завантажити документи (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw DocumentsRepositoryException(
        'Неочікуваний формат відповіді API документів.',
      );
    }

    return decoded
        .map(
          (value) => DocumentListItem.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        )
        .toList(growable: false);
  }
}

/// In-memory mock repository used for development and tests.
class MockDocumentsRepository implements DocumentsRepository {
  MockDocumentsRepository({Duration delay = const Duration(milliseconds: 400)})
    : _delay = delay;

  final Duration _delay;

  @override
  Future<List<DocumentListItem>> fetchDocuments() async {
    await Future<void>.delayed(_delay);

    final now = DateTime.now();

    return List<DocumentListItem>.unmodifiable([
      DocumentListItem(
        id: 'doc-001',
        title: 'Угода про співпрацю',
        authorId: 'user-1',
        authorName: 'Іван Петренко',
        status: const DocumentStatus(id: 's1', name: 'Очікує'),
        fileType: 'pdf',
        googleDriveFileId: 'gdrive-1',
        webViewLink: '',
        webContentLink: '',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 2)),
        signatures: const [],
        comments: const [],
        approvalFlow: const ApprovalFlow(
          isActive: true,
          steps: <ApprovalStep>[],
          currentStep: 1,
        ),
        metadata: const DocumentMetadata(
          version: 1,
          tags: <String>['contract'],
          category: 'Договори',
          fileSize: 102400,
          pageCount: 12,
        ),
      ),
      DocumentListItem(
        id: 'doc-002',
        title: 'Звіт за березень',
        authorId: 'user-2',
        authorName: 'Олена Коваль',
        status: const DocumentStatus(id: 's2', name: 'Затверджено'),
        fileType: 'xlsx',
        googleDriveFileId: 'gdrive-2',
        webViewLink: '',
        webContentLink: '',
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 30)),
        signatures: const [],
        comments: const [],
        approvalFlow: const ApprovalFlow(
          isActive: false,
          steps: <ApprovalStep>[],
          currentStep: 0,
        ),
        metadata: const DocumentMetadata(
          version: 2,
          tags: <String>['report'],
          category: 'Звіти',
          fileSize: 204800,
          pageCount: 6,
        ),
      ),
      DocumentListItem(
        id: 'doc-003',
        title: 'Заява на відпустку',
        authorId: 'user-3',
        authorName: 'Марія Сидоренко',
        status: const DocumentStatus(id: 's3', name: 'В процесі'),
        fileType: 'docx',
        googleDriveFileId: 'gdrive-3',
        webViewLink: '',
        webContentLink: '',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(hours: 20)),
        signatures: const [],
        comments: const [],
        approvalFlow: const ApprovalFlow(
          isActive: true,
          steps: <ApprovalStep>[],
          currentStep: 2,
        ),
        metadata: const DocumentMetadata(
          version: 1,
          tags: <String>['hr'],
          category: 'Заявки',
          fileSize: 51200,
          pageCount: 2,
        ),
      ),
      DocumentListItem(
        id: 'doc-004',
        title: 'Пропозиція постачальнику',
        authorId: 'user-1',
        authorName: 'Іван Петренко',
        status: const DocumentStatus(id: 's4', name: 'Відхилено'),
        fileType: 'pdf',
        googleDriveFileId: 'gdrive-4',
        webViewLink: '',
        webContentLink: '',
        createdAt: now.subtract(const Duration(days: 18)),
        updatedAt: now.subtract(const Duration(days: 15)),
        signatures: const [],
        comments: const [],
        approvalFlow: const ApprovalFlow(
          isActive: false,
          steps: <ApprovalStep>[],
          currentStep: 0,
        ),
        metadata: const DocumentMetadata(
          version: 1,
          tags: <String>['offer'],
          category: 'Документи',
          fileSize: 40960,
          pageCount: 4,
        ),
      ),
    ]);
  }
}

/// Exception thrown when the documents API cannot be read.
class DocumentsRepositoryException implements Exception {
  /// Creates an exception with a human-readable message.
  DocumentsRepositoryException(this.message);

  /// Error message shown to the user.
  final String message;

  @override
  String toString() => message;
}
