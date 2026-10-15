import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// DEV uses credentialed CORS; QA/production use the same-origin /api proxy.
/// Both clients retain HttpOnly refresh cookies through the browser adapter.
void configureWebAdapter(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(
    enableCORSWarning: false,
  );
}
