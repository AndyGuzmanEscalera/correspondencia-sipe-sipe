/// Base URL for the FastAPI backend.
///
/// In dev, Flutter Web runs on http://localhost:5000 and FastAPI on
/// http://localhost:8000. In production the Flutter app is served from
/// the same origin behind Nginx and /api proxies to FastAPI.
class ApiConfig {
  ApiConfig._();

  /// Read from `--dart-define=API_BASE_URL=...`; defaults to dev.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
}
