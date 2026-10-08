import 'package:correspondencia_api/correspondencia_api.dart';
import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingApi extends Fake implements PositionsAdminApi {
  bool? filter;
  @override
  Future<PaginatedResponse<PositionAdminResponse>> list(
      {int page = 1, int pageSize = 50, String? search, bool? isActive}) async {
    filter = isActive;
    return PaginatedResponse(
        items: [], page: page, pageSize: pageSize, total: 0, totalPages: 0);
  }
}

void main() {
  test('repository default activos conserva filtros Eliminados y Todos',
      () async {
    final api = RecordingApi();
    final repository = PositionsAdminRepository(api: api);
    await repository.list();
    expect(api.filter, isTrue);
    await repository.list(isActive: false);
    expect(api.filter, isFalse);
    await repository.list(isActive: null);
    expect(api.filter, isNull);
  });
}
