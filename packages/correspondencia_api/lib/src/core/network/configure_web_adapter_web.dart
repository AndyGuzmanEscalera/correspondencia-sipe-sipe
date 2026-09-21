import 'package:dio/browser.dart';
import 'package:dio/dio.dart';

/// Flutter Web: cookies cross-origin + JSON siempre hacen preflight OPTIONS.
/// El backend ya responde bien; silenciamos el aviso informativo de Dio.
void configureWebAdapter(Dio dio) {
  dio.httpClientAdapter = BrowserHttpClientAdapter(
    enableCORSWarning: false,
  );
}
