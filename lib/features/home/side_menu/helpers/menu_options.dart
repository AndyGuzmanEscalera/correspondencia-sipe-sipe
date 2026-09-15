import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/widgets/menu_item_data.dart';
import 'package:flutter/material.dart';

class MenuOptions {
  static List<MenuItemData> build({required Map<String, int> counts}) {
    return [
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
        menu: MenuEnum.employees,
        title: 'Funcionarios',
        icon: Icons.badge_outlined,
      ),
      MenuItemData(
        menu: MenuEnum.reports,
        title: 'Reporte general',
        icon: Icons.analytics_outlined,
      ),
    ];
  }
}
