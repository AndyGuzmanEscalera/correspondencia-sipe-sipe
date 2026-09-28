import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/views/upsert_positions_view.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertPositionsView', () {
    late _TrackingPositionsCubit listCubit;
    late _FakePositionsAdminRepository repository;

    setUp(() {
      listCubit = _TrackingPositionsCubit(_FakeListRepository());
      repository = _FakePositionsAdminRepository();
    });

    tearDown(() async {
      await listCubit.close();
    });

    Future<void> pumpUpsertDialog(
      WidgetTester tester, {
      required TypeOperation typeOperation,
      PositionAdmin? selected,
    }) async {
      if (selected != null) {
        listCubit.changeSelected(selected);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PositionsCubit>.value(
            value: listCubit,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) =>
                            BlocProvider<PositionsCubit>.value(
                          value: listCubit,
                          child: UpsertPositionsInherited(
                            typeOperation: typeOperation,
                            child: BlocProvider(
                              create: (_) =>
                                  UpsertPositionsCubit(repository),
                              child: UpsertPositionsView(
                                hostDialogContext: dialogContext,
                                ownerContext: context,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('create dialog muestra formulario vacío y code editable',
        (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Nuevo cargo'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);

      final codeField = tester.widget<AppTextField>(
        find.byType(AppTextField).first,
      );
      expect(codeField.readOnly, isFalse);
    });

    testWidgets('update dialog precarga setData y code es readonly',
        (tester) async {
      await pumpUpsertDialog(
        tester,
        typeOperation: TypeOperation.update,
        selected: _entity,
      );

      expect(find.text('Editar cargo'), findsOneWidget);
      expect(find.text('CARGO-01'), findsOneWidget);
      expect(find.text('Técnico'), findsOneWidget);

      final codeField = tester.widget<AppTextField>(
        find.byType(AppTextField).first,
      );
      expect(codeField.readOnly, isTrue);
    });

    testWidgets('error 409 mantiene el formulario abierto', (tester) async {
      repository.createResult = const Err(
        ValidationFailure(
          'Ya existe un cargo con el código indicado.',
        ),
      );

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'CARGO-01');
      await tester.enterText(find.byType(TextFormField).at(1), 'Técnico');
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nuevo cargo'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(
        find.text('Ya existe un cargo con el código indicado.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo cargo'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
    });

    testWidgets('success refresca listado y cierra upsert al confirmar éxito',
        (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'JEF');
      await tester.enterText(find.byType(TextFormField).at(1), 'Jefe');
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(listCubit.getCallCount, 1);
      expect(find.text('Nuevo cargo'), findsNothing);
      expect(find.text('Éxito'), findsOneWidget);
    });

    testWidgets('mobile 390px renderiza sin overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Nuevo cargo'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading deshabilita submit', (tester) async {
      final createGate = Completer<void>();
      repository.createGate = createGate;

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'JEF');
      await tester.enterText(find.byType(TextFormField).at(1), 'Jefe');
      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(
        tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .last
            .onPressed,
        isNull,
      );

      createGate.complete();
      await tester.pumpAndSettle();
    });
  });
}

final _entity = PositionAdmin(
  id: 'p-1',
  code: 'CARGO-01',
  name: 'Técnico',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _TrackingPositionsCubit extends PositionsCubit {
  _TrackingPositionsCubit(super.repository);

  int getCallCount = 0;

  @override
  Future<void> get() async {
    getCallCount++;
  }
}

class _FakeListRepository implements PositionsAdminRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePositionsAdminRepository implements PositionsAdminRepository {
  Result<PositionAdmin, Failure>? createResult;
  Completer<void>? createGate;

  @override
  Future<Result<PositionAdmin, Failure>> create(PositionInput input) async {
    if (createGate != null) await createGate!.future;
    return createResult ??
        Ok(
          PositionAdmin(
            id: 'p-new',
            code: input.code,
            name: input.name,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
