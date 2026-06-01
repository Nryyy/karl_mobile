/// API configuration for the application.
abstract final class ApiConfig {
  /// Base URL for the documents API.
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
