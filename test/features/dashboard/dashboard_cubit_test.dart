import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/dashboard/cubit/dashboard_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.inboxCountsResult,
    this.sentCountResult,
  });

  Result<repo.InboxCounts, Failure>? inboxCountsResult;
  Result<repo.SentCount, Failure>? sentCountResult;

  @override
  Future<Result<repo.InboxCounts, Failure>> getInboxCounts() async {
    return inboxCountsResult ?? const Ok(repo.InboxCounts(mine: 0, unit: 0));
  }

  @override
  Future<Result<repo.SentCount, Failure>> getSentCount() async {
    return sentCountResult ?? const Ok(repo.SentCount(total: 0));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DashboardCubit', () {
    test('carga counts reales de inbox y sent', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 3, unit: 7)),
        sentCountResult: const Ok(repo.SentCount(total: 22)),
      );
      final cubit = DashboardCubit(repository);

      await cubit.init();

      expect(cubit.state.mineCount, 3);
      expect(cubit.state.unitCount, 7);
      expect(cubit.state.sentCount, 22);
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('refresh actualiza métricas', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 1, unit: 2)),
        sentCountResult: const Ok(repo.SentCount(total: 4)),
      );
      final cubit = DashboardCubit(repository);

      await cubit.init();
      repository.inboxCountsResult =
          const Ok(repo.InboxCounts(mine: 5, unit: 9));
      repository.sentCountResult = const Ok(repo.SentCount(total: 11));

      await cubit.refresh();

      expect(cubit.state.mineCount, 5);
      expect(cubit.state.unitCount, 9);
      expect(cubit.state.sentCount, 11);
      await cubit.close();
    });

    test('error inbox no usa mock y conserva último valor real', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 4, unit: 8)),
        sentCountResult: const Ok(repo.SentCount(total: 6)),
      );
      final cubit = DashboardCubit(repository);

      await cubit.init();
      repository.inboxCountsResult =
          const Err(ServerFailure('falló inbox counts'));

      await cubit.refresh();

      expect(cubit.state.mineCount, 4);
      expect(cubit.state.unitCount, 8);
      await cubit.close();
    });

    test('error sent conserva último valor real', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 2, unit: 3)),
        sentCountResult: const Ok(repo.SentCount(total: 15)),
      );
      final cubit = DashboardCubit(repository);

      await cubit.init();
      repository.sentCountResult = const Err(ServerFailure('falló sent count'));

      await cubit.refresh();

      expect(cubit.state.sentCount, 15);
      await cubit.close();
    });

    test('error sin valor previo muestra placeholder neutral', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Err(ServerFailure('falló inbox counts')),
        sentCountResult: const Err(ServerFailure('falló sent count')),
      );
      final cubit = DashboardCubit(repository);

      await cubit.init();

      expect(
        cubit.state.displayCount(cubit.state.mineCount, isLoading: false),
        '—',
      );
      expect(
        cubit.state.displayCount(cubit.state.sentCount, isLoading: false),
        '—',
      );
      await cubit.close();
    });

    test('valor real cero se distingue de indisponible', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 0, unit: 0)),
        sentCountResult: const Ok(repo.SentCount(total: 0)),
      );
      final cubit = DashboardCubit(repository);

      await cubit.init();

      expect(
        cubit.state.displayCount(cubit.state.mineCount, isLoading: false),
        '0',
      );
      await cubit.close();
    });
  });
}
