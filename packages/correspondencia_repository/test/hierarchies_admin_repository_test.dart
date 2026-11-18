import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class Api extends Fake implements PositionsAdminApi {
  HierarchyRequest? request;
  String? updatedId;
  bool fail = false;
  static const row = PositionHierarchyResponse(
      id: 'h1', code: 'JEFE', name: 'Jefe', rank: 3, isActive: true);
  @override
  Future<PaginatedResponse<PositionHierarchyResponse>> listHierarchiesAdmin(
          {int page = 1,
          int pageSize = 20,
          String? search,
          bool? isActive = true}) async =>
      PaginatedResponse.fromJson({
        'items': [
          {
            'id': 'h1',
            'code': 'JEFE',
            'name': 'Jefe',
            'rank': 3,
            'is_active': true
          }
        ],
        'page': page,
        'page_size': pageSize,
        'total': 1,
        'total_pages': 1
      }, PositionHierarchyResponse.fromJson);
  @override
  Future<PositionHierarchyResponse> getHierarchy(String id) async => row;
  @override
  Future<PositionHierarchyResponse> createHierarchy(
      HierarchyRequest request) async {
    this.request = request;
    if (fail) throw Exception('synthetic');
    return row;
  }

  @override
  Future<PositionHierarchyResponse> updateHierarchy(
      String id, HierarchyRequest request) async {
    updatedId = id;
    this.request = request;
    return row;
  }

  @override
  Future<PositionHierarchyResponse> setHierarchyActive(String id,
          {required bool isActive}) async =>
      PositionHierarchyResponse(
          id: id,
          code: row.code,
          name: row.name,
          rank: row.rank,
          isActive: isActive);
}

void main() {
  test('maps hierarchy pages and detail without losing rank/state/UUID',
      () async {
    final repo = HierarchiesAdminRepository(api: Api());
    final page = (await repo.list()).valueOrNull()!;
    expect(page.items.single,
        const PositionHierarchy(id: 'h1', code: 'JEFE', name: 'Jefe', rank: 3));
    expect((await repo.get('h1')).valueOrNull()!.id, 'h1');
  });
  test('normalizes create/update payloads and preserves update ID', () async {
    final api = Api();
    final repo = HierarchiesAdminRepository(api: api);
    const input = HierarchyInput(code: ' jef ', name: ' Jefatura ', rank: 5);
    expect((await repo.create(input)).isOk, true);
    expect(api.request!.code, 'JEF');
    expect(api.request!.name, 'Jefatura');
    await repo.update('h1', input);
    expect(api.updatedId, 'h1');
    expect(api.request!.rank, 5);
    expect(
        (await repo.setActive('h1', isActive: false)).valueOrNull()!.isActive,
        false);
  });
  test('API exceptions return Failure instead of escaping to Cubit', () async {
    final api = Api()..fail = true;
    final repo = HierarchiesAdminRepository(api: api);
    expect(
        await repo.create(const HierarchyInput(code: 'J', name: 'J', rank: 1)),
        isA<Err<PositionHierarchy, Failure>>());
  });
}
