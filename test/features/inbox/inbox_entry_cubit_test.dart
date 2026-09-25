import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/cubit/inbox_entry_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.inboxResult,
    this.countsResult,
  });

  Result<repo.CorrespondencePage, Failure>? inboxResult;
  Result<repo.InboxCounts, Failure>? countsResult;

  repo.InboxScope? lastInboxScope;
  int? lastInboxPage;
  int? lastInboxPageSize;
  String? lastInboxSearch;
  int inboxCalls = 0;
  int countsCalls = 0;

  @override
  Future<Result<repo.CorrespondencePage, Failure>> getInbox({
    required repo.InboxScope scope,
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    inboxCalls++;
    lastInboxScope = scope;
    lastInboxPage = page;
    lastInboxPageSize = pageSize;
    lastInboxSearch = search;
    return inboxResult ??
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
  Future<Result<repo.InboxCounts, Failure>> getInboxCounts() async {
    countsCalls++;
    return countsResult ?? const Ok(repo.InboxCounts(mine: 0, unit: 0));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

repo.Correspondence _sampleCorrespondence() {
  return repo.Correspondence(
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
  );
}

void main() {
  group('InboxEntryCubit', () {
    test('init carga mine y counts', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxResult: Ok(
          repo.CorrespondencePage(
            items: [_sampleCorrespondence()],
            page: 1,
            pageSize: 20,
            total: 1,
            totalPages: 1,
          ),
        ),
        countsResult: const Ok(repo.InboxCounts(mine: 4, unit: 12)),
      );
      final cubit = InboxEntryCubit(repository);

      await cubit.init();

      expect(repository.lastInboxScope, repo.InboxScope.mine);
      expect(cubit.state.items.single.routeNumber, 'HR-2026-000001');
      expect(cubit.state.counts.mine, 4);
      expect(cubit.state.counts.unit, 12);
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('changeScope mine → unit', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = InboxEntryCubit(repository);

      await cubit.init();
      await cubit.changeScope(repo.InboxScope.unit);

      expect(repository.lastInboxScope, repo.InboxScope.unit);
      expect(cubit.state.scope, repo.InboxScope.unit);
      expect(cubit.state.page, 1);
      await cubit.close();
    });

    test('filter resetea page a 1', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = InboxEntryCubit(repository);

      await cubit.init();
      await cubit.changePage(2);
      cubit.filter('HR-2026');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(repository.lastInboxPage, 1);
      expect(repository.lastInboxSearch, 'HR-2026');
      expect(cubit.state.query, 'HR-2026');
      expect(cubit.state.page, 1);
      await cubit.close();
    });

    test('changePage solicita la página seleccionada', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = InboxEntryCubit(repository);

      await cubit.init();
      await cubit.changePage(3);

      expect(repository.lastInboxPage, 3);
      expect(cubit.state.page, 3);
      await cubit.close();
    });

    test('changePageSize reinicia en página 1', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = InboxEntryCubit(repository);

      await cubit.init();
      await cubit.changePage(2);
      await cubit.changePageSize(50);

      expect(repository.lastInboxPage, 1);
      expect(repository.lastInboxPageSize, 50);
      expect(cubit.state.pageSize, 50);
      await cubit.close();
    });

    test('init con scope unit abre bandeja de unidad', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = InboxEntryCubit(repository);

      await cubit.init(scope: repo.InboxScope.unit);

      expect(cubit.state.scope, repo.InboxScope.unit);
      expect(repository.lastInboxScope, repo.InboxScope.unit);
      await cubit.close();
    });

    test('init sin scope pendiente usa mine por default', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = InboxEntryCubit(repository);

      await cubit.init();

      expect(cubit.state.scope, repo.InboxScope.mine);
      expect(repository.lastInboxScope, repo.InboxScope.mine);
      await cubit.close();
    });

    test('refresh conserva scope actual', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = InboxEntryCubit(repository);

      await cubit.init();
      await cubit.changeScope(repo.InboxScope.unit);
      await cubit.refresh();

      expect(repository.lastInboxScope, repo.InboxScope.unit);
      expect(cubit.state.scope, repo.InboxScope.unit);
      await cubit.close();
    });

    test('repository error deja estado en error', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxResult: const Err(ServerFailure('falló inbox')),
      );
      final cubit = InboxEntryCubit(repository);

      await cubit.init();

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.items, isEmpty);
      await cubit.close();
    });

    test('counts error no destruye items en refresh', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxResult: Ok(
          repo.CorrespondencePage(
            items: [_sampleCorrespondence()],
            page: 1,
            pageSize: 20,
            total: 1,
            totalPages: 1,
          ),
        ),
      );
      final cubit = InboxEntryCubit(repository);

      await cubit.init();
      repository.countsResult = const Err(ServerFailure('falló counts'));
      await cubit.refresh();

      expect(cubit.state.items, isNotEmpty);
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });
  });
}
