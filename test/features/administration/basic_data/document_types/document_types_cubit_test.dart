import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list_document_types/cubit/document_types_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DocumentTypesCubit', () {
    late _FakeDocumentTypesAdminRepository repository;

    setUp(() {
      repository = _FakeDocumentTypesAdminRepository();
    });

    test('get carga list y paginación', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      final cubit = DocumentTypesCubit(repository);
      await cubit.get();

      expect(cubit.state.list.single.name, 'Carta');
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('changeSelected actualiza selected', () async {
      final cubit = DocumentTypesCubit(repository);
      cubit.changeSelected(_entity);

      expect(cubit.state.selected, _entity);
      await cubit.close();
    });

    test('filter dispara búsqueda con debounce', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      final cubit = DocumentTypesCubit(repository);
      cubit.filter('car');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await cubit.close();

      expect(repository.lastSearch, 'car');
    });

    test('changePage y changePageSize actualizan paginación', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 2,
          pageSize: 20,
          total: 100,
          totalPages: 5,
        ),
      );
      final cubit = DocumentTypesCubit(repository);
      await cubit.changePage(2);
      expect(cubit.state.page, 2);
      expect(repository.lastPage, 2);

      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 50,
          total: 100,
          totalPages: 2,
        ),
      );
      await cubit.changePageSize(50);
      expect(cubit.state.pageSize, 50);
      expect(repository.lastPage, 1);
      expect(repository.lastPageSize, 50);
      await cubit.close();
    });

    test('toggleActive reemplaza entidad devuelta', () async {
      repository.listResult = Ok(
        AdminPage(
          items: [_entity],
          page: 1,
          pageSize: 20,
          total: 1,
          totalPages: 1,
        ),
      );
      repository.setActiveResult = Ok(
        DocumentTypeAdmin(
          id: 'dt-1',
          code: 'CARTA',
          name: 'Carta',
          isActive: false,
          createdAt: _date,
          updatedAt: _date,
        ),
      );

      final cubit = DocumentTypesCubit(repository);
      await cubit.get();
      await cubit.toggleActive(_entity);

      expect(cubit.state.list.single.isActive, isFalse);
      await cubit.close();
    });
  });
}

final _entity = DocumentTypeAdmin(
  id: 'dt-1',
  code: 'CARTA',
  name: 'Carta',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _FakeDocumentTypesAdminRepository
    implements DocumentTypesAdminRepository {
  Result<AdminPage<DocumentTypeAdmin>, Failure>? listResult;
  Result<DocumentTypeAdmin, Failure>? setActiveResult;
  String? lastSearch;
  int? lastPage;
  int? lastPageSize;

  @override
  Future<Result<AdminPage<DocumentTypeAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 20,
    String? search,
    bool? isActive,
  }) async {
    lastSearch = search;
    lastPage = page;
    lastPageSize = pageSize;
    return listResult ??
        Ok(
          AdminPage(
            items: const [],
            page: page,
            pageSize: pageSize,
            total: 0,
            totalPages: 0,
          ),
        );
  }

  @override
  Future<Result<DocumentTypeAdmin, Failure>> setActive(
    String id, {
    required bool isActive,
  }) async {
    return setActiveResult ??
        const Err(ServerFailure('setActive not configured'));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
