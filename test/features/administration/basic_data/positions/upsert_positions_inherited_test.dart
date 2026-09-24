import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/result_validate.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertPositionsInherited', () {
    testWidgets('setData precarga campos en update', (tester) async {
      late UpsertPositionsInherited inherited;

      await tester.pumpWidget(
        MaterialApp(
          home: UpsertPositionsInherited(
            typeOperation: TypeOperation.update,
            child: Builder(
              builder: (context) {
                inherited = UpsertPositionsInherited.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      inherited.setData(
        PositionAdmin(
          id: 'p-1',
          code: 'CARGO-01',
          name: 'Técnico',
          description: 'Desc',
          isActive: true,
          createdAt: _date,
          updatedAt: _date,
        ),
      );

      expect(inherited.code.getValue(), 'CARGO-01');
      expect(inherited.name.getValue(), 'Técnico');
      expect(inherited.description.getValue(), 'Desc');
    });

    test('clear reinicia controllers', () {
      final inherited = UpsertPositionsInherited(
        typeOperation: TypeOperation.create,
        child: const SizedBox.shrink(),
      );
      inherited.code.setValue('X');
      inherited.name.setValue('Y');
      inherited.description.setValue('Z');

      inherited.clear();

      expect(inherited.code.getValue(), isEmpty);
      expect(inherited.name.getValue(), isEmpty);
      expect(inherited.description.getValue(), isEmpty);
      inherited.dispose();
    });

    testWidgets('valid retorna isPassed cuando el formulario es válido',
        (tester) async {
      late UpsertPositionsInherited inherited;
      ResultValidate? result;

      await tester.pumpWidget(
        MaterialApp(
          home: UpsertPositionsInherited(
            typeOperation: TypeOperation.create,
            child: Builder(
              builder: (context) {
                inherited = UpsertPositionsInherited.of(context);
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

      inherited.code.setValue('CARGO-01');
      inherited.name.setValue('Técnico');
      await tester.tap(find.text('Validar'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.isPassed, isTrue);
      inherited.dispose();
    });
  });
}

final _date = DateTime.utc(2026, 1, 1);
