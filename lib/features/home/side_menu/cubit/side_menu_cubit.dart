import 'package:correspondencia_sipe_sipe/core/data/local_store.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:flutter/material.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/helpers/menu_options.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/widgets/menu_item_data.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'side_menu_state.dart';

class SideMenuCubit extends Cubit<SideMenuState> {
  SideMenuCubit({LocalStore? store})
      : _store = store ?? LocalStore.instance,
        super(const SideMenuState());

  final LocalStore _store;

  void init({List<String> permissions = const []}) {
    final menus = MenuOptions.build(
      counts: _store.inboxCounts(),
      permissions: permissions,
    );
    final selectable = menus.where((item) => !item.isSection).toList();
    emit(
      state.copyWith(
        menus: menus,
        selected: selectable.first,
      ),
    );
  }

  void select(MenuItemData menu) {
    if (menu.isSection) return;
    emit(state.copyWith(selected: menu));
  }

  void refreshBadges({List<String> permissions = const []}) {
    final menus = MenuOptions.build(
      counts: _store.inboxCounts(),
      permissions: permissions,
    );
    final selectable = menus.where((item) => !item.isSection).toList();
    final selectedMenu = state.selected.menu;
    final selected = selectable.firstWhere(
      (item) => item.menu == selectedMenu,
      orElse: () => selectable.first,
    );
    emit(state.copyWith(menus: menus, selected: selected));
  }
}
