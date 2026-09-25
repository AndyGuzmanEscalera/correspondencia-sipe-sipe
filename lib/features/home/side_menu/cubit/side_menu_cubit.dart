import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/helpers/menu_options.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/widgets/menu_item_data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'side_menu_state.dart';

class SideMenuCubit extends Cubit<SideMenuState> {
  SideMenuCubit({
    LocalStore? store,
    repo.CorrespondenceRepository? correspondenceRepository,
  })  : _store = store ?? LocalStore.instance,
        _correspondenceRepository = correspondenceRepository,
        super(const SideMenuState());

  final LocalStore _store;
  final repo.CorrespondenceRepository? _correspondenceRepository;

  /// Último count real de inbox (mine). Nunca se rellena desde LocalStore.
  int? _lastInboxMineCount;

  void init({List<String> permissions = const []}) {
    _emitMenus(
      counts: _buildMenuCounts(),
      permissions: permissions,
    );
    unawaited(refreshBadges(permissions: permissions));
  }

  void select(MenuItemData menu) {
    if (menu.isSection) return;
    emit(state.copyWith(selected: menu));
  }

  Future<void> refreshBadges({List<String> permissions = const []}) async {
    final inboxMineCount = await _fetchInboxMineCount();
    if (inboxMineCount != null) {
      _lastInboxMineCount = inboxMineCount;
    }
    _emitMenus(counts: _buildMenuCounts(), permissions: permissions);
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

  Map<String, int?> _buildMenuCounts() {
    final mock = _store.inboxCounts();
    return {
      'inbox': _lastInboxMineCount,
      'received': mock['received'],
      'sent': mock['sent'],
    };
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
