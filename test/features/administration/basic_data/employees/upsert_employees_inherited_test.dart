import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/upsert_employees/helpers/upsert_employees_inherited.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertEmployeesInherited', () {
    testWidgets('setData precarga campos y dropdowns unit/position',
        (tester) async {
      late UpsertEmployeesInherited inherited;

      await tester.pumpWidget(
        MaterialApp(
          home: UpsertEmployeesInherited(
            typeOperation: TypeOperation.update,
            child: Builder(
              builder: (context) {
                inherited = UpsertEmployeesInherited.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      inherited.setData(
        EmployeeAdmin(
          id: 'e-1',
          firstName: 'Juan',
          lastName: 'Pérez',
          documentNumber: '123456',
          email: 'juan@test.com',
          phone: '70000000',
          unitId: 'u-1',
          unitName: 'Recepción',
          positionId: 'p-1',
          positionName: 'Técnico',
          isActive: true,
          createdAt: _date,
          updatedAt: _date,
        ),
      );

      expect(inherited.firstName.getValue(), 'Juan');
      expect(inherited.lastName.getValue(), 'Pérez');
      expect(inherited.document.getValue(), '123456');
      expect(inherited.email.getValue(), 'juan@test.com');
      expect(inherited.phone.getValue(), '70000000');
      expect(inherited.unit.getValue().value, 'u-1');
      expect(inherited.position.getValue().value, 'p-1');
    });

    test('clear reinicia controllers y dropdowns', () {
      final inherited = UpsertEmployeesInherited(
        typeOperation: TypeOperation.create,
        child: const SizedBox.shrink(),
      );
      inherited.firstName.setValue('Juan');
      inherited.lastName.setValue('Pérez');
      inherited.document.setValue('123456');
      inherited.unit.setDefaultValue(
        const FormOption<String>(id: 1, text: 'Recepción', value: 'u-1'),
      );
      inherited.position.setDefaultValue(
        const FormOption<String>(id: 2, text: 'Técnico', value: 'p-1'),
      );

      inherited.clear();

      expect(inherited.firstName.getValue(), isEmpty);
      expect(inherited.lastName.getValue(), isEmpty);
      expect(inherited.document.getValue(), isEmpty);
      expect(inherited.unit.isExist(), isFalse);
      expect(inherited.position.isExist(), isFalse);
      inherited.dispose();
    });

    testWidgets('valid retorna isPassed cuando el formulario es válido',
        (tester) async {
      late UpsertEmployeesInherited inherited;
      ResultValidate? result;

      await tester.pumpWidget(
        MaterialApp(
          home: UpsertEmployeesInherited(
            typeOperation: TypeOperation.create,
            child: Builder(
              builder: (context) {
                inherited = UpsertEmployeesInherited.of(context);
                return Scaffold(
                  body: Form(
                    key: inherited.formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: inherited.firstName.fieldKey,
                          controller: inherited.firstName.textEditingController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        TextFormField(
                          key: inherited.lastName.fieldKey,
                          controller: inherited.lastName.textEditingController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        TextFormField(
                          key: inherited.document.fieldKey,
                          controller: inherited.document.textEditingController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            result = inherited.valid();
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

      inherited.firstName.setValue('Juan');
      inherited.lastName.setValue('Pérez');
      inherited.document.setValue('123456');
      await tester.tap(find.text('Validar'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isPassed, isTrue);
      inherited.dispose();
    });
  });
}

final _date = DateTime.utc(2026, 1, 1);
