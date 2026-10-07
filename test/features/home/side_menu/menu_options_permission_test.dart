import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/helpers/menu_options.dart';
import 'package:flutter_test/flutter_test.dart';

bool _hasMenu(List<dynamic> menus, MenuEnum menu) {
  return menus.any((item) => item.menu == menu && !item.isSection);
}

bool _hasSectionTitle(List<dynamic> menus, String title) {
  return menus.any((item) => item.isSection && item.title == title);
}

void main() {
  group('MenuOptions permisos', () {
    test('A) permisos vacíos: sin ítems de datos básicos admin', () {
      final menus = MenuOptions.build(
        counts: const {},
        permissions: const [],
      );

      expect(_hasMenu(menus, MenuEnum.dashboard), isTrue);
      expect(_hasMenu(menus, MenuEnum.correspondences), isTrue);
      expect(_hasSectionTitle(menus, 'Datos básicos'), isFalse);
      expect(_hasMenu(menus, MenuEnum.adminUnits), isFalse);
      expect(_hasMenu(menus, MenuEnum.adminUsers), isFalse);
    });

    test('B) solo organizational_units.read: solo Unidades visible', () {
      final menus = MenuOptions.build(
        counts: const {},
        permissions: [Permissions.organizationalUnitsRead],
      );

      expect(_hasSectionTitle(menus, 'Datos básicos'), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminUnits), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminPositions), isFalse);
      expect(_hasMenu(menus, MenuEnum.adminEmployees), isFalse);
      expect(_hasMenu(menus, MenuEnum.adminUsers), isFalse);
      expect(_hasMenu(menus, MenuEnum.adminDocumentTypes), isFalse);
    });

    test('C) users.read + employees.read: Usuarios y Funcionarios', () {
      final menus = MenuOptions.build(
        counts: const {},
        permissions: [
          Permissions.usersRead,
          Permissions.employeesRead,
        ],
      );

      expect(_hasMenu(menus, MenuEnum.adminUsers), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminEmployees), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminUnits), isFalse);
      expect(_hasMenu(menus, MenuEnum.adminPositions), isFalse);
      expect(_hasMenu(menus, MenuEnum.adminDocumentTypes), isFalse);
    });

    test('configuración solo con system.settings.read', () {
      final menus = MenuOptions.build(
        counts: const {},
        permissions: [Permissions.systemSettingsRead],
      );

      expect(_hasSectionTitle(menus, 'Configuración'), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminConfiguration), isTrue);
    });

    test('D) los 10 permisos master_data: todos los módulos admin', () {
      final menus = MenuOptions.build(
        counts: const {},
        permissions: const [
          Permissions.organizationalUnitsRead,
          Permissions.organizationalUnitsManage,
          Permissions.positionsRead,
          Permissions.positionsManage,
          Permissions.employeesRead,
          Permissions.employeesManage,
          Permissions.usersRead,
          Permissions.usersManage,
          Permissions.documentTypesRead,
          Permissions.documentTypesManage,
        ],
      );

      expect(_hasMenu(menus, MenuEnum.adminUnits), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminPositions), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminEmployees), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminUsers), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminDocumentTypes), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminConfiguration), isFalse);
    });

    test('E) rol conceptual AUDITOR_TEST: solo por permisos efectivos', () {
      final auditorPermissions = [
        Permissions.usersRead,
        Permissions.employeesRead,
      ];
      final menus = MenuOptions.build(
        counts: const {},
        permissions: auditorPermissions,
      );

      expect(_hasMenu(menus, MenuEnum.adminUsers), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminEmployees), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminUnits), isFalse);
      expect(_hasMenu(menus, MenuEnum.adminPositions), isFalse);
      expect(_hasMenu(menus, MenuEnum.adminDocumentTypes), isFalse);
    });

    test('no deja encabezado Datos básicos sin hijos visibles', () {
      final menus = MenuOptions.build(
        counts: const {},
        permissions: [Permissions.positionsRead],
      );

      expect(_hasSectionTitle(menus, 'Datos básicos'), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminPositions), isTrue);
      expect(_hasMenu(menus, MenuEnum.adminUnits), isFalse);
    });
  });
}
