import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/cubit/derive_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/helpers/derive_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/views/derive_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackingDetailCubit extends CorrespondenceDetailCubit {
  _TrackingDetailCubit({
    required super.repository,
    required super.correspondenceId,
  });

  int refreshCallCount = 0;

  @override
  Future<void> refresh() async {
    refreshCallCount++;
  }
}

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({this.deriveResult});

  Result<repo.Correspondence, Failure>? deriveResult;
  Completer<void>? deriveGate;
  int deriveCallCount = 0;

  @override
  Future<Result<repo.Correspondence, Failure>> deriveCorrespondence(
    String correspondenceId,
    repo.DeriveCorrespondenceInput input,
  ) async {
    deriveCallCount++;
    if (deriveGate != null) {
      await deriveGate!.future;
    }
    return deriveResult ??
        Ok(
          repo.Correspondence(
            id: correspondenceId,
            routeNumber: 'HR-2026-000001',
            routeYear: 2026,
            routeSequence: 1,
            correspondenceType: 'INTERNAL',
            documentTypeCode: 'CARTA',
            documentTypeName: 'Carta',
            subject: 'Asunto',
            priority: 'MEDIUM',
            status: 'ACTIVE',
            registeredAt: DateTime.utc(2026, 1, 15),
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrganizationRepository implements repo.OrganizationRepository {
  @override
  Future<Result<List<repo.OrganizationalUnit>, Failure>>
      listActiveUnits() async {
    return Ok([
      repo.OrganizationalUnit(id: 'unit-1', code: 'SYS', name: 'Sistemas'),
    ]);
  }

  @override
  Future<Result<List<repo.UnitUser>, Failure>> listUsersByUnit(
    String unitId,
  ) async {
    return Ok([
      repo.UnitUser(
        id: 'user-1',
        username: 'dest',
        displayName: 'Usuario Destino',
      ),
    ]);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DeriveCorrespondenceView', () {
    late _TrackingDetailCubit detailCubit;
    late _FakeCorrespondenceRepository correspondenceRepository;
    late _FakeOrganizationRepository organizationRepository;
    late SideMenuCubit sideMenuCubit;

    setUp(() {
      correspondenceRepository = _FakeCorrespondenceRepository();
      organizationRepository = _FakeOrganizationRepository();
      detailCubit = _TrackingDetailCubit(
        repository: _FakeListRepository(),
        correspondenceId: 'corr-1',
      );
      sideMenuCubit = SideMenuCubit();
    });

    tearDown(() async {
      await detailCubit.close();
      await sideMenuCubit.close();
    });

    Future<void> pumpDeriveForm(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiBlocProvider(
              providers: [
                BlocProvider<CorrespondenceDetailCubit>.value(
                  value: detailCubit,
                ),
                BlocProvider<SideMenuCubit>.value(value: sideMenuCubit),
              ],
              child: DeriveCorrespondenceInherited(
                child: BlocProvider(
                  create: (_) => DeriveCorrespondenceCubit(
                    correspondenceRepository: correspondenceRepository,
                    organizationRepository: organizationRepository,
                    correspondenceId: 'corr-1',
                  ),
                  child: const DeriveCorrespondenceView(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('abre formulario y carga units', (tester) async {
      await pumpDeriveForm(tester);

      expect(find.text('Unidad destino'), findsOneWidget);
      expect(find.text('Derivar'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('cambiar unit limpia user y carga usuarios', (tester) async {
      await pumpDeriveForm(tester);

      await _selectStringDropdown(tester, optionText: 'Sistemas');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Usuario destino (opcional)'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<FormOption<String>>), findsNWidgets(2));
    });

    testWidgets('error mantiene formulario abierto', (tester) async {
      correspondenceRepository.deriveResult =
          const Err(ServerFailure('No se pudo derivar'));

      await pumpDeriveForm(tester);
      await _selectStringDropdown(tester, optionText: 'Sistemas');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Derivar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Derivar'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Derivar'), findsOneWidget);
    });

    testWidgets('success refresca DetailCubit', (tester) async {
      await pumpDeriveForm(tester);
      await _selectStringDropdown(tester, optionText: 'Sistemas');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Derivar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(detailCubit.refreshCallCount, 1);
      expect(find.text('Derivación exitosa'), findsOneWidget);
    });

    testWidgets('loading evita doble submit', (tester) async {
      final deriveGate = Completer<void>();
      correspondenceRepository.deriveGate = deriveGate;

      await pumpDeriveForm(tester);
      await _selectStringDropdown(tester, optionText: 'Sistemas');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Derivar'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      expect(correspondenceRepository.deriveCallCount, 1);

      await tester.tap(find.text('Derivar'));
      await tester.pump();
      expect(correspondenceRepository.deriveCallCount, 1);

      deriveGate.complete();
      await tester.pumpAndSettle();
    });
  });
}

class _FakeListRepository implements repo.CorrespondenceRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _selectStringDropdown(
  WidgetTester tester, {
  required String optionText,
}) async {
  final dropdown =
      find.byType(DropdownButtonFormField<FormOption<String>>).first;
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(optionText).last);
  await tester.pumpAndSettle();
}
