import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingApi extends Fake implements ApiMethod {
  Map<String, dynamic>? query;
  @override
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters, String? operation}) async {
    query = queryParameters;
    return {
      'items': [],
      'page': 1,
      'page_size': 50,
      'total': 0,
      'total_pages': 0
    };
  }
}

void main() {
  test('cinco catálogos: default activos, eliminados false, Todos explícito',
      () async {
    final transport = RecordingApi();
    final catalogs = [
      OrganizationalUnitsAdminApi(mainApi: transport),
      PositionsAdminApi(mainApi: transport),
      EmployeesAdminApi(mainApi: transport),
      UsersAdminApi(mainApi: transport),
      DocumentTypesAdminApi(mainApi: transport),
    ];
    for (final dynamic api in catalogs) {
      await api.list();
      expect(transport.query!['is_active'], isTrue);
      expect(transport.query!.containsKey('include_deleted'), isFalse);
      await api.list(isActive: false);
      expect(transport.query!['is_active'], isFalse);
      await api.list(isActive: null);
      expect(transport.query!['include_deleted'], isTrue);
      expect(transport.query!.containsKey('is_active'), isFalse);
    }
  });
}
