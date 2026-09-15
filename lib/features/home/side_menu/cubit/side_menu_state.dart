part of 'side_menu_cubit.dart';

class SideMenuState extends Equatable {
  const SideMenuState({
    this.menus = const [],
    this.selected = const MenuItemData(
      menu: MenuEnum.dashboard,
      title: 'Panel',
      icon: Icons.dashboard_outlined,
    ),
  });

  final List<MenuItemData> menus;
  final MenuItemData selected;

  SideMenuState copyWith({
    List<MenuItemData>? menus,
    MenuItemData? selected,
  }) {
    return SideMenuState(
      menus: menus ?? this.menus,
      selected: selected ?? this.selected,
    );
  }

  @override
  List<Object?> get props => [menus, selected];
}
