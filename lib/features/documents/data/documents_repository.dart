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

/// Exception thrown when the documents API cannot be read.
class DocumentsRepositoryException implements Exception {
  /// Creates an exception with a human-readable message.
  DocumentsRepositoryException(this.message);

  /// Error message shown to the user.
  final String message;

  @override
  String toString() => message;
}
