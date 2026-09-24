import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({this.listResult});

  Result<repo.CorrespondencePage, Failure>? listResult;
  int? lastListPage;
  int? lastListPageSize;
  String? lastSearch;

  @override
  Future<Result<repo.CorrespondencePage, Failure>> listCorrespondences({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? correspondenceType,
  }) async {
    lastListPage = page;
    lastListPageSize = pageSize;
    lastSearch = search;
    return listResult ??
        Ok(
          repo.CorrespondencePage(
            items: const [],
            page: page,
            pageSize: pageSize,
            total: 0,
            totalPages: 0,
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CorrespondenceCubit', () {
    test('get carga list y paginación', () async {
      final repository = _FakeCorrespondenceRepository(
        listResult: Ok(
          repo.CorrespondencePage(
            items: [
              repo.Correspondence(
                id: 'corr-1',
                routeNumber: 'HR-2026-000001',
                routeYear: 2026,
                routeSequence: 1,
                correspondenceType: 'EXTERNAL',
                documentTypeCode: 'CARTA',
                documentTypeName: 'Carta',
                subject: 'Solicitud',
                priority: 'HIGH',
                status: 'ACTIVE',
                registeredAt: DateTime.utc(2026, 1, 15),
              ),
            ],
            page: 1,
            pageSize: 20,
            total: 1,
            totalPages: 1,
          ),
        ),
      );
      final cubit = CorrespondenceCubit(repository);

      await cubit.get();

      expect(cubit.state.list.single.routeNumber, 'HR-2026-000001');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('changePage requests the selected page from repository', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceCubit(repository);

      await cubit.get();
      await cubit.changePage(3);

      expect(repository.lastListPage, 3);
      expect(cubit.state.page, 3);
      await cubit.close();
    });

    test('changePageSize resets to first page with new size', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceCubit(repository);

      await cubit.get();
      await cubit.changePage(2);
      await cubit.changePageSize(50);

      expect(repository.lastListPage, 1);
      expect(repository.lastListPageSize, 50);
      expect(cubit.state.pageSize, 50);
      await cubit.close();
    });

    test('filter resets search to page 1', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceCubit(repository);

      await cubit.get();
      await cubit.changePage(2);
      cubit.filter('HR-2026');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(repository.lastListPage, 1);
      expect(cubit.state.query, 'HR-2026');
      await cubit.close();
    });
  });
}
