import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/list_positions/cubit/positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/cubit/upsert_positions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/helpers/upsert_positions_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/administration/basic_data/positions/upsert_positions/views/upsert_positions_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:failures/failures.dart';

PositionAdmin position(bool flag) => PositionAdmin(
    id: 'position',
    code: 'ANY',
    name: 'Cargo arbitrario',
    isActive: true,
    canViewUnitCorrespondence: flag,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026));

class Repository extends Fake implements PositionsAdminRepository {
  PositionInput? saved;
  @override
  Future<Result<PositionAdmin, Failure>> create(PositionInput input) async {
    saved = input;
    return Ok(position(input.canViewUnitCorrespondence));
  }

  @override
  Future<Result<PositionAdmin, Failure>> update(
          String id, PositionInput input) =>
      create(input);
}

void main() {
  test('crear default false; update omitido conserva valor true', () async {
    final repository = Repository();
    final cubit = UpsertPositionsCubit(repository);
    await cubit.save(code: 'ANY', name: 'Director');
    expect(repository.saved!.canViewUnitCorrespondence, isFalse);
    await cubit.update(entity: position(true), name: 'Nombre nuevo');
    expect(repository.saved!.canViewUnitCorrespondence, isTrue);
    await cubit.update(
        entity: position(true),
        name: 'Nombre nuevo',
        canViewUnitCorrespondence: false);
    expect(repository.saved!.canViewUnitCorrespondence, isFalse);
    await cubit.close();
  });
  for (final edit in [false, true]) {
    testWidgets(
        'formulario Cargo edit=$edit conserva campo legado de solo lectura',
        (tester) async {
      final repository = Repository();
      final list = PositionsCubit(repository)..changeSelected(position(true));
      final cubit = UpsertPositionsCubit(repository);
      final inherited = UpsertPositionsInherited(
          typeOperation: edit ? TypeOperation.update : TypeOperation.create,
          child: MultiBlocProvider(providers: [
            BlocProvider<PositionsCubit>.value(value: list),
            BlocProvider<UpsertPositionsCubit>.value(value: cubit)
          ], child: const Scaffold(body: UpsertPositionsBody())));
      if (edit)
        inherited.setData(position(true));
      else {
        inherited.code.setValue('ANY');
        inherited.name.setValue('Director');
      }
      addTearDown(inherited.dispose);
      addTearDown(cubit.close);
      addTearDown(list.close);
      await tester.pumpWidget(MaterialApp(home: inherited));
      expect(find.text('Puede ver toda la correspondencia de su unidad'),
          findsOneWidget);
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          edit);
      expect(
          tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged,
          isNull);
      await tester.tap(find.text(edit ? 'Guardar' : 'Registrar'));
      await tester.pumpAndSettle();
      expect(repository.saved!.canViewUnitCorrespondence, edit);
    });
  }
}
