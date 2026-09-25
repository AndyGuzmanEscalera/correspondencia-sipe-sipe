import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
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

bool _hasMenu(SideMenuState state, MenuEnum menu) {
  return state.menus.any((item) => item.menu == menu && !item.isSection);
}

void main() {
  group('SideMenuCubit badges', () {
    test('inbox y sent usan API real', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 4, unit: 9)),
        sentCountResult: const Ok(repo.SentCount(total: 7)),
      );
      final cubit = SideMenuCubit(correspondenceRepository: repository);

      cubit.init();
      await cubit.refreshBadges();

      expect(_badgeFor(cubit.state, MenuEnum.inbox), 4);
      expect(_badgeFor(cubit.state, MenuEnum.sent), 7);
      await cubit.close();
    });

    test('oculta bandejas mock del menú visible', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 1, unit: 2)),
        sentCountResult: const Ok(repo.SentCount(total: 3)),
      );
      final cubit = SideMenuCubit(correspondenceRepository: repository);

      cubit.init();
      await cubit.refreshBadges();

      expect(_hasMenu(cubit.state, MenuEnum.inbox), isTrue);
      expect(_hasMenu(cubit.state, MenuEnum.sent), isTrue);
      expect(_hasMenu(cubit.state, MenuEnum.received), isFalse);
      expect(_hasMenu(cubit.state, MenuEnum.observed), isFalse);
      expect(_hasMenu(cubit.state, MenuEnum.archived), isFalse);
      await cubit.close();
    });

    test('fallo sent count conserva último valor real', () async {
      final repository = _FakeCorrespondenceRepository(
        inboxCountsResult: const Ok(repo.InboxCounts(mine: 2, unit: 5)),
        sentCountResult: const Ok(repo.SentCount(total: 8)),
      );
      final cubit = SideMenuCubit(correspondenceRepository: repository);

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
      final cubit = SideMenuCubit(correspondenceRepository: repository);

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
      final cubit = SideMenuCubit(correspondenceRepository: repository);

      cubit.init();
      await cubit.refreshBadges();
      expect(_badgeFor(cubit.state, MenuEnum.inbox), 6);

      repository.inboxCountsResult =
          const Err(ServerFailure('falló inbox count'));
      await cubit.refreshBadges();

      expect(_badgeFor(cubit.state, MenuEnum.inbox), 6);
      await cubit.close();
    });

    test('navigateToInbox deja scope pendiente para InboxEntryView', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = SideMenuCubit(correspondenceRepository: repository);

      cubit.init();
      await cubit.refreshBadges();
      cubit.navigateToInbox(scope: repo.InboxScope.unit);

      expect(cubit.state.selected.menu, MenuEnum.inbox);
      expect(cubit.consumePendingInboxScope(), repo.InboxScope.unit);
      expect(cubit.consumePendingInboxScope(), isNull);
      await cubit.close();
    });

    test('pending scope se consume una sola vez', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = SideMenuCubit(correspondenceRepository: repository);

      cubit.init();
      await cubit.refreshBadges();
      cubit.navigateToInbox(scope: repo.InboxScope.unit);

      expect(cubit.consumePendingInboxScope(), repo.InboxScope.unit);
      expect(cubit.consumePendingInboxScope(), isNull);
      expect(cubit.consumePendingInboxScope(), isNull);
      await cubit.close();
    });

    test('sidebar bandeja limpia pending stale y abre default mine', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = SideMenuCubit(correspondenceRepository: repository);

      cubit.init();
      await cubit.refreshBadges();

      cubit.navigateToInbox(scope: repo.InboxScope.unit);
      final panel = cubit.state.menus.firstWhere(
        (item) => item.menu == MenuEnum.dashboard && !item.isSection,
      );
      cubit.select(panel);

      final inbox = cubit.state.menus.firstWhere(
        (item) => item.menu == MenuEnum.inbox && !item.isSection,
      );
      cubit.select(inbox);

      expect(cubit.consumePendingInboxScope(), isNull);
      await cubit.close();
    });
  });
}
