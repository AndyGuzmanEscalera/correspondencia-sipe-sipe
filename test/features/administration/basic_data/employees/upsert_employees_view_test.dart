import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/list_employees/cubit/employees_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/upsert_employees/cubit/upsert_employees_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/upsert_employees/helpers/upsert_employees_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/employees/upsert_employees/views/upsert_employees_view.dart';
import 'dart:async';

import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UpsertEmployeesView', () {
    late _TrackingEmployeesCubit listCubit;
    late _FakeEmployeesAdminRepository employeesRepository;
    late _FakeOrganizationalUnitsAdminRepository unitsRepository;
    late _FakePositionsAdminRepository positionsRepository;

    setUp(() {
      listCubit = _TrackingEmployeesCubit(_FakeListRepository());
      employeesRepository = _FakeEmployeesAdminRepository();
      unitsRepository = _FakeOrganizationalUnitsAdminRepository();
      positionsRepository = _FakePositionsAdminRepository();
    });

    tearDown(() async {
      await listCubit.close();
    });

    Future<void> pumpUpsertDialog(
      WidgetTester tester, {
      required TypeOperation typeOperation,
      EmployeeAdmin? selected,
    }) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      if (selected != null) {
        listCubit.changeSelected(selected);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<EmployeesCubit>.value(
            value: listCubit,
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => BlocProvider<EmployeesCubit>.value(
                          value: listCubit,
                          child: UpsertEmployeesInherited(
                            typeOperation: typeOperation,
                            child: BlocProvider(
                              create: (_) => UpsertEmployeesCubit(
                                employeesRepository: employeesRepository,
                                unitsRepository: unitsRepository,
                                positionsRepository: positionsRepository,
                              ),
                              child: const UpsertEmployeesView(),
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

    testWidgets('create dialog muestra formulario vacío', (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Nuevo funcionario'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Nombres'), findsOneWidget);
    });

    testWidgets('update dialog precarga setData', (tester) async {
      await pumpUpsertDialog(
        tester,
        typeOperation: TypeOperation.update,
        selected: _entity,
      );

      expect(find.text('Editar funcionario'), findsOneWidget);
      expect(find.text('Juan'), findsOneWidget);
      expect(find.text('Pérez'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
    });

    testWidgets('muestra dropdowns cuando catálogos cargan', (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      expect(find.text('Unidad'), findsOneWidget);
      expect(find.text('Cargo'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(DropdownButtonFormField<FormOption<String>>).first);
      await tester.pumpAndSettle();

      expect(find.text('Recepción'), findsOneWidget);
    });

    testWidgets('error 409 mantiene el formulario abierto', (tester) async {
      employeesRepository.createResult = const Err(
        ValidationFailure(
          'Ya existe un funcionario con el documento 123456.',
        ),
      );

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'Juan');
      await tester.enterText(find.byType(TextFormField).at(1), 'Pérez');
      await tester.enterText(find.byType(TextFormField).at(2), '123456');

      await _selectDropdownOption(tester, dropdownIndex: 0, optionText: 'Recepción');
      await _selectDropdownOption(tester, dropdownIndex: 1, optionText: 'Técnico');

      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nuevo funcionario'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);
      expect(
        find.text('Ya existe un funcionario con el documento 123456.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo funcionario'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
    });

    testWidgets('success refresca listado y cierra upsert al confirmar éxito',
        (tester) async {
      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'María');
      await tester.enterText(find.byType(TextFormField).at(1), 'López');
      await tester.enterText(find.byType(TextFormField).at(2), '654321');

      await _selectDropdownOption(tester, dropdownIndex: 0, optionText: 'Recepción');
      await _selectDropdownOption(tester, dropdownIndex: 1, optionText: 'Técnico');

      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(listCubit.getCallCount, 1);
      expect(find.text('Nuevo funcionario'), findsOneWidget);
      expect(find.text('Éxito'), findsOneWidget);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Nuevo funcionario'), findsNothing);
    });

    testWidgets('loading impide doble submit', (tester) async {
      final createGate = Completer<void>();
      employeesRepository.createGate = createGate;

      await pumpUpsertDialog(tester, typeOperation: TypeOperation.create);

      await tester.enterText(find.byType(TextFormField).at(0), 'María');
      await tester.enterText(find.byType(TextFormField).at(1), 'López');
      await tester.enterText(find.byType(TextFormField).at(2), '654321');

      await _selectDropdownOption(tester, dropdownIndex: 0, optionText: 'Recepción');
      await _selectDropdownOption(tester, dropdownIndex: 1, optionText: 'Técnico');

      await tester.tap(find.text('Registrar'));
      await tester.pump();

      expect(
        tester
            .widgetList<ElevatedButton>(find.byType(ElevatedButton))
            .last
            .onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      createGate.complete();
      await tester.pumpAndSettle();
    });
  });
}

final _entity = EmployeeAdmin(
  id: 'e-1',
  firstName: 'Juan',
  lastName: 'Pérez',
  documentNumber: '123456',
  unitId: 'u-1',
  unitName: 'Recepción',
  positionId: 'p-1',
  positionName: 'Técnico',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _unit = OrganizationalUnitAdmin(
  id: 'u-1',
  code: 'REC',
  name: 'Recepción',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _position = PositionAdmin(
  id: 'p-1',
  code: 'TEC',
  name: 'Técnico',
  isActive: true,
  createdAt: _date,
  updatedAt: _date,
);

final _date = DateTime.utc(2026, 1, 1);

Future<void> _selectDropdownOption(
  WidgetTester tester, {
  required int dropdownIndex,
  required String optionText,
}) async {
  final dropdown =
      find.byType(DropdownButtonFormField<FormOption<String>>).at(dropdownIndex);
  await tester.scrollUntilVisible(
    dropdown,
    48,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(optionText).last);
  await tester.pumpAndSettle();
}

class _TrackingEmployeesCubit extends EmployeesCubit {
  _TrackingEmployeesCubit(super.repository);

  int getCallCount = 0;

  @override
  Future<void> get() async {
    getCallCount++;
  }
}

class _FakeListRepository implements EmployeesAdminRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEmployeesAdminRepository implements EmployeesAdminRepository {
  Result<EmployeeAdmin, Failure>? createResult;
  Completer<void>? createGate;

  @override
  Future<Result<EmployeeAdmin, Failure>> create(EmployeeInput input) async {
    if (createGate != null) {
      await createGate!.future;
    }
    return createResult ??
        Ok(
          EmployeeAdmin(
            id: 'e-new',
            firstName: input.firstName,
            lastName: input.lastName,
            documentNumber: input.documentNumber,
            unitId: input.unitId,
            positionId: input.positionId,
            isActive: true,
            createdAt: _date,
            updatedAt: _date,
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrganizationalUnitsAdminRepository
    implements OrganizationalUnitsAdminRepository {
  @override
  Future<Result<AdminPage<OrganizationalUnitAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    return Ok(
      AdminPage(
        items: [_unit],
        page: 1,
        pageSize: 100,
        total: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePositionsAdminRepository implements PositionsAdminRepository {
  @override
  Future<Result<AdminPage<PositionAdmin>, Failure>> list({
    int page = 1,
    int pageSize = 50,
    String? search,
    bool? isActive,
  }) async {
    return Ok(
      AdminPage(
        items: [_position],
        page: 1,
        pageSize: 100,
        total: 1,
        totalPages: 1,
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
