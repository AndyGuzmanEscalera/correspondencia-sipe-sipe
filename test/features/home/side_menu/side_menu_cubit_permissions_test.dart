import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SideMenuCubit permisos', () {
    test('refreshBadges sin argumentos conserva permisos de init', () async {
      final cubit = SideMenuCubit();
      cubit.init(
        permissions: [Permissions.usersRead, Permissions.employeesRead],
      );

      await cubit.refreshBadges();

      final hasUsers = cubit.state.menus.any(
        (item) => item.menu == MenuEnum.adminUsers && !item.isSection,
      );
      final hasUnits = cubit.state.menus.any(
        (item) => item.menu == MenuEnum.adminUnits && !item.isSection,
      );
      expect(hasUsers, isTrue);
      expect(hasUnits, isFalse);

      await cubit.close();
    });

    test('refreshBadges puede actualizar permisos explícitos', () async {
      final cubit = SideMenuCubit();
      cubit.init(permissions: [Permissions.usersRead]);

      await cubit.refreshBadges(
        permissions: [Permissions.organizationalUnitsRead],
      );

      final hasUsers = cubit.state.menus.any(
        (item) => item.menu == MenuEnum.adminUsers && !item.isSection,
      );
      final hasUnits = cubit.state.menus.any(
        (item) => item.menu == MenuEnum.adminUnits && !item.isSection,
      );
      expect(hasUsers, isFalse);
      expect(hasUnits, isTrue);

      await cubit.close();
    });
  });
}
