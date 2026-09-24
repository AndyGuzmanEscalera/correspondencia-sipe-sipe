import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/users/upsert_users/helpers/upsert_users_inherited.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertUsersInherited', () {
    testWidgets('setData precarga username, email, employee y roles', (tester) async {
      late UpsertUsersInherited inherited;

      await tester.pumpWidget(
        MaterialApp(
          home: UpsertUsersInherited(
            typeOperation: TypeOperation.update,
            child: Builder(
              builder: (context) {
                inherited = UpsertUsersInherited.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      inherited.setData(
        UserAdmin(
          id: 'u-1',
          username: 'admin',
          email: 'admin@test.com',
          employeeId: 'e-1',
          employeeName: 'Juan Pérez',
          isActive: true,
          roleCodes: const ['ADMIN'],
          createdAt: _date,
          updatedAt: _date,
        ),
      );
      inherited.setRolesFromCatalog(
        UserAdmin(
          id: 'u-1',
          username: 'admin',
          isActive: true,
          roleCodes: const ['ADMIN'],
          createdAt: _date,
          updatedAt: _date,
        ),
        const [RoleOption(id: 'r-1', code: 'ADMIN', name: 'Administrador')],
      );

      expect(inherited.username.getValue(), 'admin');
      expect(inherited.email.getValue(), 'admin@test.com');
      expect(inherited.password.getValue(), isEmpty);
      expect(inherited.employee.getValue().value, 'e-1');
      expect(inherited.selectedRoleIds, {'r-1'});
    });

    test('clear reinicia controllers, password y roles', () {
      final inherited = UpsertUsersInherited(
        typeOperation: TypeOperation.create,
        child: const SizedBox.shrink(),
      );
      inherited.username.setValue('admin');
      inherited.email.setValue('admin@test.com');
      inherited.password.setValue('Secret123');
      inherited.employee.setDefaultValue(
        const FormOption<String>(id: 1, text: 'Juan', value: 'e-1'),
      );
      inherited.selectedRoleIds.add('r-1');

      inherited.clear();

      expect(inherited.username.getValue(), isEmpty);
      expect(inherited.password.getValue(), isEmpty);
      expect(inherited.employee.isExist(), isFalse);
      expect(inherited.selectedRoleIds, isEmpty);
      inherited.dispose();
    });

    testWidgets('valid create exige password y roles', (tester) async {
      late UpsertUsersInherited inherited;
      ResultValidate? result;

      await tester.pumpWidget(
        MaterialApp(
          home: UpsertUsersInherited(
            typeOperation: TypeOperation.create,
            child: Builder(
              builder: (context) {
                inherited = UpsertUsersInherited.of(context);
                return Scaffold(
                  body: Form(
                    key: inherited.formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: inherited.username.fieldKey,
                          controller: inherited.username.textEditingController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        TextFormField(
                          key: inherited.password.fieldKey,
                          controller: inherited.password.textEditingController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            result = inherited.valid(isCreate: true);
                          },
                          child: const Text('Validar'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      inherited.username.setValue('admin');
      inherited.password.setValue('Secret123');
      inherited.selectedRoleIds.add('r-1');
      await tester.tap(find.text('Validar'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isPassed, isTrue);
      inherited.dispose();
    });
  });
}

final _date = DateTime.utc(2026, 1, 1);
