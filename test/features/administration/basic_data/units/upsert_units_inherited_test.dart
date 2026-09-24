import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/upsert_units/helpers/upsert_units_inherited.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertUnitsInherited', () {
    testWidgets('setData precarga campos y parent unit', (tester) async {
      late UpsertUnitsInherited inherited;

      await tester.pumpWidget(
        MaterialApp(
          home: UpsertUnitsInherited(
            typeOperation: TypeOperation.update,
            child: Builder(
              builder: (context) {
                inherited = UpsertUnitsInherited.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      inherited.setData(
        OrganizationalUnitAdmin(
          id: 'u-1',
          code: 'REC',
          name: 'Recepción',
          description: 'Desc',
          parentId: 'u-2',
          parentName: 'Secretaría',
          isActive: true,
          createdAt: _date,
          updatedAt: _date,
        ),
      );

      expect(inherited.code.getValue(), 'REC');
      expect(inherited.name.getValue(), 'Recepción');
      expect(inherited.description.getValue(), 'Desc');
      expect(inherited.parent.getValue().value, 'u-2');
    });

    test('clear reinicia controllers y parent default', () {
      final inherited = UpsertUnitsInherited(
        typeOperation: TypeOperation.create,
        child: const SizedBox.shrink(),
      );
      inherited.code.setValue('X');
      inherited.name.setValue('Y');
      inherited.description.setValue('Z');
      inherited.parent.setDefaultValue(
        const FormOption<String>(id: 1, text: 'Parent', value: 'p-1'),
      );

      inherited.clear();

      expect(inherited.code.getValue(), isEmpty);
      expect(inherited.name.getValue(), isEmpty);
      expect(inherited.description.getValue(), isEmpty);
      expect(inherited.parent.getValue(), UpsertUnitsInherited.noParent);
      inherited.dispose();
    });

    testWidgets('valid retorna isPassed cuando el formulario es válido',
        (tester) async {
      late UpsertUnitsInherited inherited;
      ResultValidate? result;

      await tester.pumpWidget(
        MaterialApp(
          home: UpsertUnitsInherited(
            typeOperation: TypeOperation.create,
            child: Builder(
              builder: (context) {
                inherited = UpsertUnitsInherited.of(context);
                return Scaffold(
                  body: Form(
                    key: inherited.formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          key: inherited.code.fieldKey,
                          controller: inherited.code.textEditingController,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Requerido'
                              : null,
                        ),
                        TextFormField(
                          key: inherited.name.fieldKey,
                          controller: inherited.name.textEditingController,
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

      inherited.code.setValue('REC');
      inherited.name.setValue('Recepción');
      inherited.parent.setDefaultValue(UpsertUnitsInherited.noParent);
      await tester.tap(find.text('Validar'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isPassed, isTrue);
      inherited.dispose();
    });
  });
}

final _date = DateTime.utc(2026, 1, 1);
