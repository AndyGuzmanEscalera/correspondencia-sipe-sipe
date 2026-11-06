import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public tracking POST has only the two lookup fields, without JWT',
      () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(options.path, '/public/correspondence/track');
      expect(options.method, 'POST');
      expect(options.headers.containsKey('Authorization'), isFalse);
      expect(options.queryParameters, isEmpty);
      expect(options.data, {
        'route_sheet_number': 'HR-2026-000123',
        'document_number': '12345678'
      });
      handler.resolve(Response(
          requestOptions: options, statusCode: 200, data: {'found': false}));
    }));
    final response = await PublicTrackingApi(api: ApiMethod(dio: dio))
        .trackRouteSheet(
            const PublicTrackingRequest(' hr-2026-000123 ', ' 12345678 '));
    expect(response.found, isFalse);
    expect(response.movements, isEmpty);
  });
  test('explicit public DTO ignores internal fields', () {
    final response = PublicTrackingResponse.fromJson({
      'found': true,
      'user_id': 'private',
      'route_sheet_number': 'HR-2026-000123',
      'status_label': 'Recibido',
      'movements': [
        {
          'date': '2026-11-06T12:00:00Z',
          'status': 'RECEIVED',
          'label': 'Recibido',
          'observation': 'private'
        }
      ]
    });
    expect(response.movements.single.label, 'Recibido');
    expect(response.routeSheetNumber, 'HR-2026-000123');
  });
  test('default public client does not carry auth interceptors', () {
    final dio = ApiClient.buildRefresh();
    expect(dio.interceptors.whereType<AuthInterceptor>(), isEmpty);
    expect(dio.interceptors.whereType<AuthRefreshInterceptor>(), isEmpty);
  });
}
