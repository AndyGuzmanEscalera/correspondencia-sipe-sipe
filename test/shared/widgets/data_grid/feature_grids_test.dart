import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/theme/app_theme.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/tables/employees_table.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/tables/units_table.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/list_users/tables/users_table.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/tables/correspondence_table.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/data_grid/app_data_grid_action.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../features/correspondence/detail/detail_test_fixtures.dart';

void main() {
  group('Feature Grids UI & Responsive (Bloque 3)', () {
    final now = DateTime(2026, 3, 20);

    final sampleUnits = [
      OrganizationalUnitAdmin(
        id: 'u-1',
        code: 'SEC-GEN',
        name: 'Secretaría General Municipal',
        parentName: 'Despacho del Alcalde',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      OrganizationalUnitAdmin(
        id: 'u-2',
        code: 'DIR-OBR',
        name: 'Dirección de Obras Públicas e Infraestructura Vial',
        parentName: 'Secretaría General Municipal',
        isActive: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final sampleEmployees = [
      EmployeeAdmin(
        id: 'e-1',
        firstName: 'Juan Carlos',
        lastName: 'Choquehuanca Morales',
        documentNumber: '4839201 LP',
        unitName: 'Dirección de Planificación Urbana',
        positionName: 'Director de Planificación',
        email: 'jchoque@sipesipe.gob.bo',
        phone: '71234567',
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      EmployeeAdmin(
        id: 'e-2',
        firstName: 'Ana María',
        lastName: 'Rodríguez Zurita',
        documentNumber: '5849302 CBBA',
        unitName: 'Unidad de Sistemas y Tecnologías',
        positionName: 'Administradora de Base de Datos',
        email: 'arodriguez@sipesipe.gob.bo',
        phone: '72345678',
        isActive: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final sampleUsers = [
      UserAdmin(
        id: 'usr-1',
        username: 'admin.general',
        employeeName: 'Juan Carlos Choquehuanca Morales',
        unitName: 'Secretaría General Municipal',
        roleCodes: const ['ADMIN', 'SUPERVISOR'],
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
      UserAdmin(
        id: 'usr-2',
        username: 'operador.sistemas',
        employeeName: 'Ana María Rodríguez Zurita',
        unitName: 'Unidad de Sistemas y Tecnologías',
        roleCodes: const ['OPERADOR'],
        isActive: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final sampleCorrespondences = [
      externalCorrespondence,
      internalCorrespondence,
      inactiveResponsibleCorrespondence,
    ];

    Future<void> pumpGridWidget(
      WidgetTester tester, {
      required double width,
      required double height,
      required Widget grid,
    }) async {
      await tester.binding.setSurfaceSize(Size(width, height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: height,
              child: grid,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Units grid renders desktop table and mobile cards without overflow', (tester) async {
      // Desktop 1366
      await pumpGridWidget(
        tester,
        width: 1366,
        height: 768,
        grid: AppDataGrid<OrganizationalUnitAdmin>(
          items: sampleUnits,
          columns: unitsTableColumns(),
          actions: [
            AppDataGridAction<OrganizationalUnitAdmin>(
              icon: Icons.edit_outlined,
              tooltip: 'Editar',
              onPressed: (_) {},
            ),
          ],
        ),
      );
      expect(find.byType(DataTable2), findsOneWidget);
      expect(find.text('Secretaría General Municipal'), findsWidgets);
      expect(find.text('ACTIVO'), findsOneWidget);
      expect(find.text('INACTIVO'), findsOneWidget);

      // Mobile 390
      await pumpGridWidget(
        tester,
        width: 390,
        height: 844,
        grid: AppDataGrid<OrganizationalUnitAdmin>(
          items: sampleUnits,
          columns: unitsTableColumns(),
          actions: [
            AppDataGridAction<OrganizationalUnitAdmin>(
              icon: Icons.edit_outlined,
              tooltip: 'Editar',
              onPressed: (_) {},
            ),
          ],
        ),
      );
      expect(find.byType(DataTable2), findsNothing);
      expect(find.text('Secretaría General Municipal'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Employees grid renders desktop and mobile with long data without overflow', (tester) async {
      // Desktop 1024
      await pumpGridWidget(
        tester,
        width: 1024,
        height: 768,
        grid: AppDataGrid<EmployeeAdmin>(
          items: sampleEmployees,
          columns: employeesTableColumns(),
        ),
      );
      expect(find.byType(DataTable2), findsOneWidget);
      expect(find.text('Juan Carlos Choquehuanca Morales'), findsOneWidget);

      // Mobile 430
      await pumpGridWidget(
        tester,
        width: 430,
        height: 932,
        grid: AppDataGrid<EmployeeAdmin>(
          items: sampleEmployees,
          columns: employeesTableColumns(),
        ),
      );
      expect(find.byType(DataTable2), findsNothing);
      expect(find.text('Juan Carlos Choquehuanca Morales'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Users grid renders desktop and mobile clean structure', (tester) async {
      // Mobile 390
      await pumpGridWidget(
        tester,
        width: 390,
        height: 844,
        grid: AppDataGrid<UserAdmin>(
          items: sampleUsers,
          columns: usersTableColumns(),
        ),
      );
      expect(find.byType(DataTable2), findsNothing);
      expect(find.text('admin.general'), findsOneWidget);
      expect(find.text('ADMIN, SUPERVISOR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Correspondence grid renders desktop and mobile without overflow', (tester) async {
      // Desktop 1366
      await pumpGridWidget(
        tester,
        width: 1366,
        height: 768,
        grid: AppDataGrid<CorrespondenceEntity>(
          items: sampleCorrespondences,
          columns: correspondenceTableColumns(),
          currentPage: 1,
          pageSize: 10,
          totalItems: 3,
          totalPages: 1,
          onPageChanged: (_) {},
        ),
      );
      expect(find.byType(DataTable2), findsOneWidget);
      expect(find.text('HR-2026-000001'), findsOneWidget);
      expect(find.text('Encadenamiento'), findsOneWidget);
      expect(find.text('Informe Técnico'), findsOneWidget);
      expect(find.textContaining('Carlos Pérez · Inactivo'), findsOneWidget);
      expect(find.text('ACTIVO'), findsWidgets);

      // Mobile 390
      await pumpGridWidget(
        tester,
        width: 390,
        height: 844,
        grid: AppDataGrid<CorrespondenceEntity>(
          items: sampleCorrespondences,
          columns: correspondenceTableColumns(),
          currentPage: 1,
          pageSize: 10,
          totalItems: 3,
          totalPages: 1,
          onPageChanged: (_) {},
        ),
      );
      expect(find.byType(DataTable2), findsNothing);
      expect(find.text('HR-2026-000001'), findsOneWidget);
      expect(find.text('Encadenamiento'), findsWidgets);
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.textContaining('Carlos Pérez · Inactivo'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
