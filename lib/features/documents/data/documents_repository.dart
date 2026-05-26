import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../domain/document_models.dart';

/// Abstraction for fetching documents from a data source.
abstract class DocumentsRepository {
  /// Loads the latest documents.
  Future<List<DocumentListItem>> fetchDocuments();

  /// Creates a new document and returns its id.
  Future<String> createDocument({
    required String title,
    required String authorId,
    required String authorName,
    String? statusId,
    String? statusName,
    String? fileType,
    String? organizationId,
    List<CreateApprovalStep>? approvalSteps,
  });

  /// Returns the backend profile for the given Firebase UID.
  Future<UserProfile> fetchCurrentUser(String uid);

  /// Returns a list of all users (for approver selection).
  Future<List<UserProfile>> fetchUsers();

  /// Returns distinct statuses extracted from existing documents.
  Future<List<DocumentStatus>> fetchDocumentStatuses();

  /// Uploads a file for an existing document.
  Future<UploadDocumentFileResponse> uploadDocumentFile({
    required String documentId,
    required Uint8List fileBytes,
    required String fileName,
  });
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
  Future<UserProfile> fetchCurrentUser(String uid) async {
    final uri = Uri.parse('$baseUrl/api/Users/$uid');
    final headers = <String, String>{'accept': 'application/json'};
    final accessToken = await _accessTokenProvider?.call();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['authorization'] = 'Bearer $accessToken';
    }

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode != 200) {
      developer.log(
        'Users API returned ${response.statusCode} for uid=$uid.',
        name: 'karl.users',
        error: response.body,
      );
      throw DocumentsRepositoryException(
        'Не вдалося отримати профіль користувача (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    return UserProfile.fromJson(Map<String, dynamic>.from(decoded as Map));
  }

  @override
  Future<List<UserProfile>> fetchUsers() async {
    final uri = Uri.parse('$baseUrl/api/Users');
    final headers = <String, String>{'accept': 'application/json'};
    final accessToken = await _accessTokenProvider?.call();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['authorization'] = 'Bearer $accessToken';
    }

    final response = await _client.get(uri, headers: headers);

    if (response.statusCode != 200) {
      developer.log(
        'Users API returned ${response.statusCode}.',
        name: 'karl.users',
        error: response.body,
      );
      throw DocumentsRepositoryException(
        'Не вдалося отримати список користувачів (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw DocumentsRepositoryException(
        'Неочікуваний формат відповіді API користувачів.',
      );
    }
    return decoded
        .map(
          (value) =>
              UserProfile.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList(growable: false);
  }

  @override
  Future<List<DocumentStatus>> fetchDocumentStatuses() async {
    final documents = await fetchDocuments();
    final seen = <String>{};
    return documents
        .map((d) => d.status)
        .where((s) => s.id.isNotEmpty && seen.add(s.id))
        .toList(growable: false);
  }

  @override
  Future<String> createDocument({
    required String title,
    required String authorId,
    required String authorName,
    String? statusId,
    String? statusName,
    String? fileType,
    String? organizationId,
    List<CreateApprovalStep>? approvalSteps,
  }) async {
    final uri = Uri.parse('$baseUrl/api/Documents');
    final headers = <String, String>{
      'accept': 'application/json',
      'content-type': 'application/json',
    };
    final accessToken = await _accessTokenProvider?.call();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['authorization'] = 'Bearer $accessToken';
    }

    final bodyMap = <String, dynamic>{
      'title': title,
      'authorId': authorId,
      'authorName': authorName,
      if (statusId != null && statusId.isNotEmpty) 'statusId': statusId,
      if (statusName != null && statusName.isNotEmpty) 'statusName': statusName,
      if (fileType != null && fileType.isNotEmpty) 'fileType': fileType,
      if (organizationId != null && organizationId.isNotEmpty)
        'organizationId': organizationId,
      if (approvalSteps != null && approvalSteps.isNotEmpty)
        'approvalSteps': approvalSteps.map((s) => s.toJson()).toList(),
    };

    final body = jsonEncode(bodyMap);

    final response = await _client.post(uri, headers: headers, body: body);

    if (response.statusCode == 401) {
      developer.log(
        'Documents API returned 401 on create.',
        name: 'karl.documents',
        error: response.body,
      );
      throw DocumentsRepositoryException(
        'Сесія авторизації недійсна. Увійдіть ще раз.',
      );
    }

    if (response.statusCode != 201) {
      developer.log(
        'Documents API returned ${response.statusCode} on create.',
        name: 'karl.documents',
        error: response.body,
      );
      throw DocumentsRepositoryException(
        'Не вдалося створити документ (${response.statusCode}).',
      );
    }

    final location = response.headers['location'] ?? '';
    if (location.isNotEmpty) {
      return location.split('/').last;
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final id = decoded['id']?.toString() ?? '';
        if (id.isNotEmpty) return id;
      }
    } catch (_) {}

    throw DocumentsRepositoryException(
      'Не вдалося отримати ідентифікатор нового документа.',
    );
  }

  @override
  Future<UploadDocumentFileResponse> uploadDocumentFile({
    required String documentId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/api/Documents/$documentId/file');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

    final accessToken = await _accessTokenProvider?.call();
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['authorization'] = 'Bearer $accessToken';
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      developer.log(
        'Documents API returned 401 on file upload.',
        name: 'karl.documents',
        error: response.body,
      );
      throw DocumentsRepositoryException(
        'Сесія авторизації недійсна. Увійдіть ще раз.',
      );
    }

    if (response.statusCode != 200) {
      developer.log(
        'Documents API returned ${response.statusCode} on file upload.',
        name: 'karl.documents',
        error: response.body,
      );
      final detail = _extractDetail(response.body);
      final isGoogleDrive =
          detail.toLowerCase().contains('google drive') ||
          detail.toLowerCase().contains('google account');
      throw DocumentsRepositoryException(
        isGoogleDrive
            ? 'Google Drive не підключено. Зверніться до адміністратора для підключення облікового запису Google.'
            : 'Не вдалося завантажити файл (${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    return UploadDocumentFileResponse.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
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

String _extractDetail(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return decoded['detail']?.toString() ?? decoded['title']?.toString() ?? '';
    }
  } catch (_) {}
  return body;
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
