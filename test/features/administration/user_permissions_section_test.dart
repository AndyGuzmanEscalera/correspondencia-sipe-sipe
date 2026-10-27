import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/widgets/user_permissions_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const permission = PermissionOption(
      id: 'p',
      code: 'master_data.users.read',
      description: 'Consultar usuarios');
  for (final allowed in [true, false]) {
    testWidgets('permisos directos editable=$allowed', (tester) async {
      final form = UpsertUsersInherited(
          typeOperation: TypeOperation.create,
          child: MaterialApp(
              home: Scaffold(
                  body: UserPermissionsSection(
                      permissions: const [permission], canManage: allowed))));
      addTearDown(form.dispose);
      await tester.pumpWidget(form);
      await tester.tap(find.text('Administración'));
      await tester.pumpAndSettle();
      final tile =
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(tile.onChanged == null, !allowed);
      if (allowed) {
        await tester.tap(find.text('Consultar usuarios'));
        await tester.pumpAndSettle();
        expect(form.selectedPermissionIds, {'p'});
      }
    });
  }
  test('categorías del catálogo no dependen del nombre del rol', () {
    expect(const PermissionOption(id: '1', code: 'reports.view').category,
        'Reportes');
    expect(
        const PermissionOption(id: '2', code: 'correspondence.create').category,
        'Correspondencia - Creación');
    expect(
        const PermissionOption(id: '3', code: 'system.settings.manage')
            .category,
        'Configuración');
    expect(
        const PermissionOption(id: '4', code: 'rrhh.read').category, 'Otros');
  });
}
