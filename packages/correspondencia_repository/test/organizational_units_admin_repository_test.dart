import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

OrganizationalUnitsAdminApi _apiWithHandler(
  Future<Response<dynamic>> Function(RequestOptions options) handler,
) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, requestHandler) async {
        try {
          final response = await handler(options);
          requestHandler.resolve(response);
        } catch (error) {
          requestHandler.reject(
            DioException(requestOptions: options, error: error),
          );
        }
      },
    ),
  );
  return OrganizationalUnitsAdminApi(mainApi: ApiMethod(dio: dio));
}

void main() {
  group('OrganizationalUnitsAdminRepository', () {
    test('list maps paginated admin units', () async {
      final repo = OrganizationalUnitsAdminRepository(
        api: _apiWithHandler(
          (options) async => Response<dynamic>(
            requestOptions: options,
            statusCode: 200,
            data: {
              'items': [
                {
                  'id': 'unit-1',
                  'code': 'SISTEMAS',
                  'name': 'Unidad de Sistemas',
                  'description': null,
                  'parent_id': null,
                  'parent_name': null,
                  'is_active': true,
                  'created_at': '2026-01-15T00:00:00Z',
                  'updated_at': '2026-01-15T00:00:00Z',
                  'created_by_user_id': null,
                  'updated_by_user_id': null,
                },
              ],
              'page': 1,
              'page_size': 20,
              'total': 1,
              'total_pages': 1,
            },
          ),
        ),
      );

      final result = await repo.list();

      expect(result.isOk, isTrue);
      final page = result.valueOrNull();
      expect(page?.items.single.code, 'SISTEMAS');
      expect(page?.items.single.name, 'Unidad de Sistemas');
      expect(page?.total, 1);
    });
  });
}
