import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/helpers/menu_options.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/widgets/menu_item_data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'side_menu_state.dart';

class SideMenuCubit extends Cubit<SideMenuState> {
  SideMenuCubit({
    repo.CorrespondenceRepository? correspondenceRepository,
    this.onBadgesRefresh,
  })  : _correspondenceRepository = correspondenceRepository,
        super(const SideMenuState());

  final repo.CorrespondenceRepository? _correspondenceRepository;
  final Future<void> Function()? onBadgesRefresh;

  /// Último count real de inbox (mine). Nunca se rellena desde LocalStore.
  int? _lastInboxMineCount;

  /// Último count real de enviados. Nunca se rellena desde LocalStore.
  int? _lastSentCount;

  /// Permisos efectivos de la sesión (reutilizados al refrescar badges).
  List<String> _sessionPermissions = const [];
  int _sessionGeneration = 0;

  repo.InboxScope? _pendingInboxScope;

  void init({List<String> permissions = const []}) {
    ++_sessionGeneration;
    _lastInboxMineCount = null;
    _lastSentCount = null;
    _sessionPermissions = permissions;
    _emitMenus(
      counts: _buildMenuCounts(),
      permissions: permissions,
    );
    unawaited(refreshBadges());
  }

  void select(MenuItemData menu, {bool preservePendingInboxScope = false}) {
    if (menu.isSection) return;
    if (!preservePendingInboxScope) {
      _pendingInboxScope = null;
    }
    emit(state.copyWith(selected: menu));
  }

  void navigateToInbox({required repo.InboxScope scope}) {
    _pendingInboxScope = scope;
    _selectMenu(MenuEnum.inbox, preservePendingInboxScope: true);
  }

  void navigateToMenu(MenuEnum menu) => _selectMenu(menu);

  void navigateToSent() {
    _selectMenu(MenuEnum.sent);
  }

  repo.InboxScope? consumePendingInboxScope() {
    final scope = _pendingInboxScope;
    _pendingInboxScope = null;
    return scope;
  }

  Future<void> refreshBadges({List<String>? permissions}) async {
    final generation = _sessionGeneration;
    await onBadgesRefresh?.call();
    if (permissions != null) {
      _sessionPermissions = permissions;
    }
    final results = await Future.wait([
      _fetchInboxMineCount(),
      _fetchSentCount(),
    ]);
    if (isClosed || generation != _sessionGeneration) return;
    final inboxMineCount = results[0];
    final sentCount = results[1];
    if (inboxMineCount != null) {
      _lastInboxMineCount = inboxMineCount;
    }
    if (sentCount != null) {
      _lastSentCount = sentCount;
    }
    _emitMenus(counts: _buildMenuCounts(), permissions: _sessionPermissions);
  }

  Future<int?> _fetchInboxMineCount() async {
    final repository = _correspondenceRepository;
    if (repository == null) return null;

    final result = await repository.getInboxCounts();
    return result.when(
      ok: (counts) => counts.mine,
      err: (_) => null,
    );
  }

  Future<int?> _fetchSentCount() async {
    final repository = _correspondenceRepository;
    if (repository == null) return null;

    final result = await repository.getSentCount();
    return result.when(
      ok: (count) => count.total,
      err: (_) => null,
    );
  }

  Map<String, int?> _buildMenuCounts() {
    return {
      'inbox': _lastInboxMineCount,
      'sent': _lastSentCount,
    };
  }

  void _selectMenu(
    MenuEnum menu, {
    bool preservePendingInboxScope = false,
  }) {
    final selectable = state.menus.where((item) => !item.isSection).toList();
    if (selectable.isEmpty) return;

    final selected = selectable.firstWhere(
      (item) => item.menu == menu,
      orElse: () => selectable.first,
    );
    select(selected, preservePendingInboxScope: preservePendingInboxScope);
  }

  void _emitMenus({
    required Map<String, int?> counts,
    required List<String> permissions,
  }) {
    final menus = MenuOptions.build(
      counts: counts,
      permissions: permissions,
    );
    final selectable = menus.where((item) => !item.isSection).toList();
    if (selectable.isEmpty) {
      emit(state.copyWith(menus: menus));
      return;
    }

    final selectedMenu = state.selected.menu;
    final selected = selectable.firstWhere(
      (item) => item.menu == selectedMenu,
      orElse: () => selectable.first,
    );
    emit(state.copyWith(menus: menus, selected: selected));
  }
}
