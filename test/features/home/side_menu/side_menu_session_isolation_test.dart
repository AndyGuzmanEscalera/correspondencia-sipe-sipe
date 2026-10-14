import 'dart:async';
import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _Repository implements repo.CorrespondenceRepository {
  final oldInbox = Completer<Result<repo.InboxCounts, Failure>>(),
      oldSent = Completer<Result<repo.SentCount, Failure>>();
  int inboxCalls = 0, sentCalls = 0;
  @override
  Future<Result<repo.InboxCounts, Failure>> getInboxCounts() async =>
      ++inboxCalls == 1
          ? oldInbox.future
          : const Ok(repo.InboxCounts(mine: 2, unit: 0));
  @override
  Future<Result<repo.SentCount, Failure>> getSentCount() async =>
      ++sentCalls == 1 ? oldSent.future : const Ok(repo.SentCount(total: 3));
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('new session discards previous actor badge responses', () async {
    final repository = _Repository(),
        cubit = SideMenuCubit(correspondenceRepository: repository);
    cubit.init();
    await Future<void>.delayed(Duration.zero);
    cubit.init();
    await cubit.refreshBadges();
    repository.oldInbox
        .complete(const Ok(repo.InboxCounts(mine: 99, unit: 99)));
    repository.oldSent.complete(const Ok(repo.SentCount(total: 99)));
    await Future<void>.delayed(Duration.zero);
    expect(
        cubit.state.menus.firstWhere((m) => !m.isSection && m.menu == MenuEnum.inbox).badge, 2);
    expect(
        cubit.state.menus.firstWhere((m) => !m.isSection && m.menu == MenuEnum.sent).badge, 3);
    await cubit.close();
  });
}
