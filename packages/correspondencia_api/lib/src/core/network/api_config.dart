import 'package:flutter/foundation.dart';

/// Shared configuration for the main client and the refresh client.
class ApiConfig {
  ApiConfig._();

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kDebugMode ? 'development' : 'production',
  );

  /// Public endpoint only. No credentials or backend secrets belong here.
  static const String productionBaseUrl =
      'https://api-correspondencia.sipesipe.gob.bo/api';

  /// Pages uses the separate API host. Debian recovery builds explicitly pass
  /// API_BASE_URL=/api; local development can select its own backend.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: environment == 'production'
        ? productionBaseUrl
        : kIsWeb && environment == 'qa'
            ? '/api'
            : 'http://localhost:8000',
  );
}
