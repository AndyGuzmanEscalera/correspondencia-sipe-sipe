import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/list_units/cubit/units_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/upsert_units/cubit/upsert_units_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/upsert_units/helpers/upsert_units_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/units/upsert_units/views/upsert_units_view.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/form/app_text_field.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertUnitsView', () {
    late _TrackingUnitsCubit listCubit;
    late _FakeOrganizationalUnitsAdminRepository repository;

    setUp(() {
      listCubit = _TrackingUnitsCubit(_FakeListRepository());
      repository = _FakeOrganizationalUnitsAdminRepository();
    });

    tearDown(() async {
      await listCubit.close();
    });

    Future<void> pumpUpsertDialog(
      WidgetTester tester, {
      required TypeOperation typeOperation,
      OrganizationalUnitAdmin? selected,
    }) async {
      if (selected != null) {
        listCubit.changeSelected(selected);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<UnitsCubit>.value(
            value: listCubit,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) =>
                            BlocProvider<UnitsCubit>.value(
                          value: listCubit,
                          child: UpsertUnitsInherited(
                            typeOperation: typeOperation,
                            child: BlocProvider(
                              create: (_) => UpsertUnitsCubit(repository),
                              child: UpsertUnitsView(
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

      expect(find.text('Nueva unidad'), findsOneWidget);
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

      expect(find.text('Editar unidad'), findsOneWidget);
      expect(find.text('REC'), findsOneWidget);
      expect(find.text('Recepción'), findsOneWidget);

      final codeField = tester.widget<AppTextField>(
        find.byType(AppTextField).first,
      );
      expect(codeField.readOnly, isTrue);
    });

    testWidgets('muestra dropdown de parent cuando catálogo carga',
        (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Unidad superior (opcional)'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<FormOption<String>>));
      await tester.pumpAndSettle();

      expect(find.text('Sin unidad superior'), findsOneWidget);
      expect(find.text('Secretaría'), findsOneWidget);
    });

    testWidgets('error 409 mantiene el formulario abierto', (tester) async {
      repository.createResult = const Err(
        ValidationFailure(
          'Ya existe una unidad organizacional con el código indicado.',
        ),
      );

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'ABC');
      await tester.enterText(find.byType(TextFormField).at(1), 'Recepción');
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nueva unidad'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(
        find.text('Ya existe una unidad organizacional con el código indicado.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva unidad'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
    });

    testWidgets('success refresca listado y cierra formulario sin pulsar Cerrar',
        (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'JUR');
      await tester.enterText(find.byType(TextFormField).at(1), 'Jurídica');
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(listCubit.getCallCount, 1);
      expect(find.text('Nueva unidad'), findsNothing);
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

      expect(find.text('Nueva unidad'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading deshabilita submit', (tester) async {
      final createGate = Completer<void>();
      repository.createGate = createGate;

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'FIN');
      await tester.enterText(find.byType(TextFormField).at(1), 'Finanzas');
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

final _entity = OrganizationalUnitAdmin(
  id: 'u-1',
  code: 'REC',
  name: 'Recepción',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _parent = OrganizationalUnitAdmin(
  id: 'u-2',
  code: 'SEC',
  name: 'Secretaría',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

class _TrackingUnitsCubit extends UnitsCubit {
  _TrackingUnitsCubit(super.repository);

  int getCallCount = 0;

  @override
  Future<void> get() async {
    getCallCount++;
  }
}

class _FakeListRepository implements OrganizationalUnitsAdminRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrganizationalUnitsAdminRepository
    implements OrganizationalUnitsAdminRepository {
  Result<OrganizationalUnitAdmin, Failure>? createResult;
  Completer<void>? createGate;

  @override
  Future<Result<AdminPage<OrganizationalUnitAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    return Ok(
      AdminPage(
        items: [_parent],
        page: 1,
        pageSize: 100,
        total: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  Future<Result<OrganizationalUnitAdmin, Failure>> create(
    OrganizationalUnitInput input,
  ) async {
    if (createGate != null) await createGate!.future;
    return createResult ??
        Ok(
          OrganizationalUnitAdmin(
            id: 'u-new',
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
