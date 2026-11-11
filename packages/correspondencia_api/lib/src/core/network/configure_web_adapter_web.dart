import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Credentialed requests support local CORS, Pages/API subdomains and recovery proxy.
/// Both clients retain HttpOnly refresh cookies through the browser adapter.
void configureWebAdapter(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(
    enableCORSWarning: false,
  );
}
