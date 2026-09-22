import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/widgets/menu_item_data.dart';
import 'package:flutter/material.dart';

class MenuOptions {
  static List<MenuItemData> build({
    required Map<String, int> counts,
    List<String> permissions = const [],
  }) {
    final all = [
      MenuItemData(
        menu: MenuEnum.dashboard,
        title: 'Panel',
        icon: Icons.dashboard_outlined,
      ),
      MenuItemData(
        menu: MenuEnum.correspondences,
        title: 'Correspondencias',
        icon: Icons.description_outlined,
      ),
      const MenuItemData(
        menu: MenuEnum.inbox,
        title: 'Hojas de ruta',
        icon: Icons.route_outlined,
        isSection: true,
      ),
      MenuItemData(
        menu: MenuEnum.inbox,
        title: 'Bandeja de entrada',
        icon: Icons.inbox_outlined,
        badge: counts['inbox'],
      ),
      MenuItemData(
        menu: MenuEnum.received,
        title: 'Recibidos',
        icon: Icons.move_to_inbox_outlined,
        badge: counts['received'],
      ),
      MenuItemData(
        menu: MenuEnum.sent,
        title: 'Enviados',
        icon: Icons.send_outlined,
        badge: counts['sent'],
      ),
      MenuItemData(
        menu: MenuEnum.observed,
        title: 'Observados',
        icon: Icons.report_problem_outlined,
      ),
      MenuItemData(
        menu: MenuEnum.archived,
        title: 'Archivados',
        icon: Icons.archive_outlined,
      ),
      MenuItemData(
        menu: MenuEnum.reports,
        title: 'Reporte general',
        icon: Icons.analytics_outlined,
      ),
      const MenuItemData(
        menu: MenuEnum.administration,
        title: 'Administración',
        icon: Icons.admin_panel_settings_outlined,
        isSection: true,
      ),
      const MenuItemData(
        menu: MenuEnum.basicData,
        title: 'Datos básicos',
        icon: Icons.storage_outlined,
        isSection: true,
      ),
      MenuItemData(
        menu: MenuEnum.adminUnits,
        title: 'Unidades organizacionales',
        icon: Icons.account_tree_outlined,
        requiredPermission: Permissions.organizationalUnitsRead,
      ),
      MenuItemData(
        menu: MenuEnum.adminPositions,
        title: 'Cargos',
        icon: Icons.work_outline,
        requiredPermission: Permissions.positionsRead,
      ),
      MenuItemData(
        menu: MenuEnum.adminEmployees,
        title: 'Funcionarios',
        icon: Icons.badge_outlined,
        requiredPermission: Permissions.employeesRead,
      ),
      MenuItemData(
        menu: MenuEnum.adminUsers,
        title: 'Usuarios',
        icon: Icons.people_outline,
        requiredPermission: Permissions.usersRead,
      ),
      MenuItemData(
        menu: MenuEnum.adminDocumentTypes,
        title: 'Tipos de documento',
        icon: Icons.category_outlined,
        requiredPermission: Permissions.documentTypesRead,
      ),
    ];

    return _filterByPermissions(all, permissions);
  }

  static List<MenuItemData> _filterByPermissions(
    List<MenuItemData> items,
    List<String> permissions,
  ) {
    bool canSee(MenuItemData item) {
      final code = item.requiredPermission;
      if (code == null) return true;
      return permissions.contains(code);
    }

    final result = <MenuItemData>[];
    var index = 0;
    while (index < items.length) {
      final item = items[index];
      if (!item.isSection) {
        if (canSee(item)) result.add(item);
        index++;
        continue;
      }

      final sectionHeader = item;
      index++;
      final visibleChildren = <MenuItemData>[];
      while (index < items.length && !items[index].isSection) {
        final child = items[index];
        if (canSee(child)) visibleChildren.add(child);
        index++;
      }

      if (visibleChildren.isNotEmpty) {
        result.add(sectionHeader);
        result.addAll(visibleChildren);
      }
    }

    return result.isEmpty ? items.take(1).toList() : result;
  }
}
