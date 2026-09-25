import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
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

int? _badgeFor(SideMenuState state, MenuEnum menu) {
  return state.menus
      .firstWhere((item) => item.menu == menu && !item.isSection)
      .badge;
}

void main() {
  group('SideMenuCubit badges', () {
    late LocalStore store;

    setUp(() {
      store = LocalStore.instance;
      store.seed();
    });

    test('inbox y sent usan API real', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 4, unit: 9)),
        sentCountResult: const Ok(repo.SentCount(total: 7)),
      );
      final cubit = SideMenuCubit(
        store: store,
        correspondenceRepository: repository,
      );

      cubit.init();
      await cubit.refreshBadges();

      expect(_badgeFor(cubit.state, MenuEnum.inbox), 4);
      expect(_badgeFor(cubit.state, MenuEnum.sent), 7);
      await cubit.close();
    });

    test('received sigue usando mock LocalStore', () async {
      final mockReceived = store.inboxCounts()['received'];
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 1, unit: 2)),
        sentCountResult: const Ok(repo.SentCount(total: 3)),
      );
      final cubit = SideMenuCubit(
        store: store,
        correspondenceRepository: repository,
      );

      cubit.init();
      await cubit.refreshBadges();

      expect(_badgeFor(cubit.state, MenuEnum.received), mockReceived);
      await cubit.close();
    });

    test('fallo sent count conserva último valor real', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 2, unit: 5)),
        sentCountResult: const Ok(repo.SentCount(total: 8)),
      );
      final cubit = SideMenuCubit(
        store: store,
        correspondenceRepository: repository,
      );

      cubit.init();
      await cubit.refreshBadges();
      expect(_badgeFor(cubit.state, MenuEnum.sent), 8);

      repository.sentCountResult = const Err(ServerFailure('falló sent count'));
      await cubit.refreshBadges();

      expect(_badgeFor(cubit.state, MenuEnum.sent), 8);
      await cubit.close();
    });

    test('fallo sent count sin valor previo oculta badge', () async {
      final repository = _FakeCorrespondenceRepository(
        sentCountResult: const Err(ServerFailure('falló sent count')),
      );
      final cubit = SideMenuCubit(
        store: store,
        correspondenceRepository: repository,
      );

      cubit.init();
      await cubit.refreshBadges();

      expect(_badgeFor(cubit.state, MenuEnum.sent), isNull);
      await cubit.close();
    });

    test('fallo inbox count conserva último valor real', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 6, unit: 10)),
        sentCountResult: const Ok(repo.SentCount(total: 1)),
      );
      final cubit = SideMenuCubit(
        store: store,
        correspondenceRepository: repository,
      );

      cubit.init();
      await cubit.refreshBadges();
      expect(_badgeFor(cubit.state, MenuEnum.inbox), 6);

      repository.inboxCountsResult =
          const Err(ServerFailure('falló inbox count'));
      await cubit.refreshBadges();

      expect(_badgeFor(cubit.state, MenuEnum.inbox), 6);
      await cubit.close();
    });
  });
}
