import 'package:flutter/foundation.dart';

/// Single source of truth for both main and refresh clients.
/// Release web builds always use Apache's same-origin /api proxy.
class ApiConfig {
  ApiConfig._();

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kDebugMode ? 'development' : 'production',
  );

  static const bool _sameOrigin = kIsWeb &&
      (!kDebugMode || environment == 'qa' || environment == 'production');

  /// API_BASE_URL only overrides development (or native clients).
  /// A release web build cannot accidentally ship a development/LAN address.
  static const String baseUrl = _sameOrigin
      ? '/api'
      : String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:8000',
        );
}
