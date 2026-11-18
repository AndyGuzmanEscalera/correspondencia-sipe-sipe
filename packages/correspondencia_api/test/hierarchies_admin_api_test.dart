import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:flutter_test/flutter_test.dart';

class Transport extends Fake implements ApiMethod {
  String? path, method;
  Object? body;
  Map<String, dynamic>? query;
  Map<String, dynamic> row = {
    'id': 'h1',
    'code': 'JEFE',
    'name': 'Jefatura',
    'rank': 3,
    'is_active': true
  };
  @override
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParameters, String? operation}) async {
    this.path = path;
    method = 'GET';
    query = queryParameters;
    return queryParameters == null
        ? row
        : {
            'items': [row],
            'page': 1,
            'page_size': 20,
            'total': 1,
            'total_pages': 1
          };
  }

  @override
  Future<Map<String, dynamic>> post(String path,
      {Object? data, String? operation, bool allowEmptyBody = false}) async {
    this.path = path;
    method = 'POST';
    body = data;
    return row;
  }

  @override
  Future<Map<String, dynamic>> put(String path,
      {Object? data, String? operation}) async {
    this.path = path;
    method = 'PUT';
    body = data;
    return row;
  }

  @override
  Future<Map<String, dynamic>> patch(String path,
      {Object? data, String? operation}) async {
    this.path = path;
    method = 'PATCH';
    body = data;
    return {...row, 'is_active': (data as Map)['is_active']};
  }
}

void main() {
  test('hierarchy list supports paging search and active/deleted/all',
      () async {
    final transport = Transport();
    final api = PositionsAdminApi(mainApi: transport);
    final page = await api.listHierarchiesAdmin(search: 'jef', pageSize: 20);
    expect(page.items.single.rank, 3);
    expect(transport.path, '/admin/positions/hierarchies');
    expect(transport.query,
        {'page': 1, 'page_size': 20, 'search': 'jef', 'is_active': true});
    await api.listHierarchiesAdmin(isActive: false);
    expect(transport.query!['is_active'], false);
    await api.listHierarchiesAdmin(isActive: null);
    expect(transport.query!['include_deleted'], true);
    expect(transport.query!.containsKey('is_active'), false);
  });
  test(
      'hierarchy detail create update and state use the existing backend routes',
      () async {
    final transport = Transport();
    final api = PositionsAdminApi(mainApi: transport);
    expect((await api.getHierarchy('h1')).id, 'h1');
    expect(transport.method, 'GET');
    const request = HierarchyRequest(code: 'JEFE', name: 'Jefatura', rank: 3);
    await api.createHierarchy(request);
    expect(transport.method, 'POST');
    expect(transport.body, request.toJson());
    await api.updateHierarchy(
        'h1', const HierarchyRequest(code: 'JEF', name: 'Nuevo', rank: 4));
    expect(transport.method, 'PUT');
    expect(transport.path, '/admin/positions/hierarchies/h1');
    expect((transport.body as Map)['code'], 'JEF');
    expect(
        (await api.setHierarchyActive('h1', isActive: false)).isActive, false);
    expect(transport.path, '/admin/positions/hierarchies/h1/active');
    expect(transport.method, 'PATCH');
    expect(transport.body, {'is_active': false});
  });
}
