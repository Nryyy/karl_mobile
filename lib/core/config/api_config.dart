/// API configuration for the application.
import 'package:flutter/foundation.dart';

abstract final class ApiConfig {
  /// Base URL for the documents API.
  /// Use HTTPS for localhost (server listens HTTPS). In debug the HTTP client
  /// accepts self-signed localhost certificates so local testing works.
  static const String baseUrl = 'https://localhost:7229';

  /// API version prefix.
  static const String apiVersion = '/api';

  /// Timeout duration for API requests.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Number of retry attempts for failed requests.
  static const int maxRetries = 3;

  /// Delay between retry attempts.
  static const Duration retryDelay = Duration(seconds: 1);
}
