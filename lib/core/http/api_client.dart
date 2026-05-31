import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

import '../config/api_config.dart';

/// Centralized API client with interceptors, retry logic, and error handling.
class ApiClient {
  ApiClient({
    http.Client? client,
    Future<String?> Function()? accessTokenProvider,
  })  : _client = client ?? http.Client(),
        _accessTokenProvider = accessTokenProvider;

  final http.Client _client;
  final Future<String?> Function()? _accessTokenProvider;

  /// Returns the current access token if available.
  Future<String?> getAccessToken() async => _accessTokenProvider?.call();

  /// Performs a GET request with retry logic.
  Future<http.Response> get(String path) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}$path');
      final headers = await _buildHeaders();
      
      developer.log('GET $uri', name: 'api.client');
      return await _client.get(uri, headers: headers).timeout(ApiConfig.requestTimeout);
    });
  }

  /// Performs a POST request with retry logic.
  Future<http.Response> post(String path, {Map<String, dynamic>? body}) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}$path');
      final headers = await _buildHeaders();
      if (body != null) {
        headers['content-type'] = 'application/json';
      }
      
      developer.log('POST $uri', name: 'api.client');
      return await _client.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.requestTimeout);
    });
  }

  /// Performs a PUT request with retry logic.
  Future<http.Response> put(String path, {Map<String, dynamic>? body}) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}$path');
      final headers = await _buildHeaders();
      if (body != null) {
        headers['content-type'] = 'application/json';
      }
      
      developer.log('PUT $uri', name: 'api.client');
      return await _client.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.requestTimeout);
    });
  }

  /// Performs a DELETE request with retry logic.
  Future<http.Response> delete(String path) async {
    return _executeWithRetry(() async {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiVersion}$path');
      final headers = await _buildHeaders();
      
      developer.log('DELETE $uri', name: 'api.client');
      return await _client.delete(uri, headers: headers).timeout(ApiConfig.requestTimeout);
    });
  }

  /// Executes request with retry logic for transient failures.
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
  ) async {
    int attempts = 0;
    
    while (attempts < ApiConfig.maxRetries) {
      attempts++;
      
      try {
        final response = await request();
        
        // Don't retry on 4xx errors (client errors)
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return response;
        }
        
        // Success or non-retryable error
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        
        // Retry on 5xx server errors
        if (attempts < ApiConfig.maxRetries) {
          developer.log(
            'Retry $attempts/${ApiConfig.maxRetries} after ${response.statusCode}',
            name: 'api.client',
          );
          await Future.delayed(ApiConfig.retryDelay * attempts);
        }
      } on TimeoutException catch (e) {
        if (attempts >= ApiConfig.maxRetries) {
          rethrow;
        }
        developer.log(
          'Retry $attempts/${ApiConfig.maxRetries} after timeout',
          name: 'api.client',
          error: e,
        );
        await Future.delayed(ApiConfig.retryDelay * attempts);
      }
    }
    
    throw Exception('Max retries exceeded');
  }

  /// Builds request headers with authorization.
  Future<Map<String, String>> _buildHeaders() async {
    final headers = <String, String>{
      'accept': 'application/json',
    };
    
    final accessToken = await _accessTokenProvider?.call();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['authorization'] = 'Bearer $accessToken';
    }
    
    return headers;
  }

  void dispose() {
    _client.close();
  }
}
