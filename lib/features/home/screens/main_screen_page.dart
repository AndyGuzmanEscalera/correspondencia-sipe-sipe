import 'package:correspondencia_sipe_sipe/core/auth/permission_guard.dart';
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_layout.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/document_types/list/views/document_types_list_page.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list/views/employees_list_page.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list/views/positions_list_page.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list/views/units_list_page.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list/views/users_list_page.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list/views/correspondence_list_page.dart';
import 'package:correspondencia_sipe_sipe/features/dashboard/views/dashboard_page.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/widgets/side_menu_widget.dart';
import 'package:correspondencia_sipe_sipe/features/home/widgets/admin_app_bar.dart';
import 'package:correspondencia_sipe_sipe/features/inbox/views/inbox_page.dart';
import 'package:correspondencia_sipe_sipe/features/reports/views/reports_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainScreenPage extends StatelessWidget {
  const MainScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScreenView();
  }
}

class MainScreenView extends StatelessWidget {
  const MainScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainScreenBody();
  }
}

class MainScreenBody extends StatefulWidget {
  const MainScreenBody({super.key});

  @override
  State<MainScreenBody> createState() => _MainScreenBodyState();
}

class _MainScreenBodyState extends State<MainScreenBody> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (device, longitude) {
        final showSidebar = longitude == DeviceLongitude.long;
        final content = Column(
          children: [
            AdminAppBar(
              onMenuTap: showSidebar ? null : () => _scaffoldKey.currentState?.openDrawer(),
            ),
            BlocSelector<SideMenuCubit, SideMenuState, MenuEnum>(
              selector: (state) => state.selected.menu,
              builder: (context, menu) => _ContentArea(menu: menu),
            ),
          ],
        );

        if (showSidebar) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SideMenuWidget(),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8FAFC),
          drawer: Drawer(
            child: SideMenuWidget(
              onItemSelected: () => Navigator.of(context).pop(),
            ),
          ),
          body: content,
        );
      },
    );
  }
}

class _ContentArea extends StatelessWidget {
  const _ContentArea({required this.menu});

  final MenuEnum menu;

  @override
  Widget build(BuildContext context) {
    return switch (menu) {
      MenuEnum.dashboard => const DashboardPage(),
      MenuEnum.correspondences => const CorrespondenceListPage(),
      MenuEnum.inbox => const InboxPage(inboxType: InboxType.inbox),
      MenuEnum.received => const InboxPage(inboxType: InboxType.received),
      MenuEnum.sent => const InboxPage(inboxType: InboxType.sent),
      MenuEnum.observed => const InboxPage(inboxType: InboxType.observed),
      MenuEnum.archived => const InboxPage(inboxType: InboxType.archived),
      MenuEnum.reports => const ReportsPage(),
      MenuEnum.adminUnits => PermissionGuard(
          permission: Permissions.organizationalUnitsRead,
          child: const UnitsListPage(),
        ),
      MenuEnum.adminPositions => PermissionGuard(
          permission: Permissions.positionsRead,
          child: const PositionsListPage(),
        ),
      MenuEnum.adminEmployees => PermissionGuard(
          permission: Permissions.employeesRead,
          child: const EmployeesListPage(),
        ),
      MenuEnum.adminUsers => PermissionGuard(
          permission: Permissions.usersRead,
          child: const UsersListPage(),
        ),
      MenuEnum.adminDocumentTypes => PermissionGuard(
          permission: Permissions.documentTypesRead,
          child: const DocumentTypesListPage(),
        ),
      MenuEnum.administration ||
      MenuEnum.basicData ||
      MenuEnum.settings =>
        const DashboardPage(),
    };
  }
}
