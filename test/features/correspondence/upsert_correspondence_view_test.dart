import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackingCorrespondenceCubit extends CorrespondenceCubit {
  _TrackingCorrespondenceCubit(super.repository);

  int getCallCount = 0;

  @override
  Future<void> get() async {
    getCallCount++;
  }
}

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({this.createResult});

  Result<repo.Correspondence, Failure>? createResult;
  Completer<void>? createGate;

  @override
  Future<Result<repo.Correspondence, Failure>> createCorrespondence(
    repo.CreateCorrespondenceInput input,
  ) async {
    if (createGate != null) {
      await createGate!.future;
    }
    return createResult ??
        Ok(
          repo.Correspondence(
            id: 'corr-new',
            routeNumber: 'HR-2026-000099',
            routeYear: 2026,
            routeSequence: 99,
            correspondenceType: input.correspondenceType,
            documentTypeCode: 'CARTA',
            documentTypeName: 'Carta',
            subject: input.subject,
            priority: input.priority,
            status: 'ACTIVE',
            registeredAt: DateTime.utc(2026, 1, 15),
          ),
        );
  }

  @override
  Future<Result<List<repo.DocumentType>, Failure>> listDocumentTypes() async {
    return Ok([
      repo.DocumentType(id: 'dt-1', code: 'CARTA', name: 'Carta'),
    ]);
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

class _FakeDetailCorrespondenceRepository
    implements repo.CorrespondenceRepository {
  @override
  Future<Result<repo.Correspondence, Failure>> getCorrespondence(
    String id,
  ) async {
    return Ok(
      repo.Correspondence(
        id: id,
        routeNumber: 'HR-2026-000099',
        routeYear: 2026,
        routeSequence: 99,
        correspondenceType: 'EXTERNAL',
        documentTypeCode: 'CARTA',
        documentTypeName: 'Carta',
        subject: 'Solicitud externa',
        priority: 'HIGH',
        status: 'ACTIVE',
        registeredAt: DateTime.utc(2026, 1, 15),
      ),
    );
  }

  @override
  Future<Result<List<repo.CorrespondenceMovement>, Failure>> listMovements(
    String correspondenceId,
  ) async {
    return const Ok([]);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NavObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
  }
}

void main() {
  group('UpsertCorrespondenceView', () {
    late _TrackingCorrespondenceCubit listCubit;
    late _FakeCorrespondenceRepository correspondenceRepository;
    late _FakeOrganizationRepository organizationRepository;
    late SideMenuCubit sideMenuCubit;
    late _NavObserver navObserver;

    setUp(() {
      correspondenceRepository = _FakeCorrespondenceRepository();
      organizationRepository = _FakeOrganizationRepository();
      listCubit = _TrackingCorrespondenceCubit(_FakeListRepository());
      sideMenuCubit = SideMenuCubit();
      navObserver = _NavObserver();

      if (getIt.isRegistered<CorrespondenceDetailCubit>()) {
        getIt.unregister<CorrespondenceDetailCubit>();
      }
      getIt.registerFactoryParam<CorrespondenceDetailCubit, String, void>(
        (correspondenceId, _) => CorrespondenceDetailCubit(
          repository: _FakeDetailCorrespondenceRepository(),
          correspondenceId: correspondenceId,
        ),
      );
    });

    tearDown(() async {
      await listCubit.close();
      await sideMenuCubit.close();
      if (getIt.isRegistered<CorrespondenceDetailCubit>()) {
        getIt.unregister<CorrespondenceDetailCubit>();
      }
    });

    Future<void> pumpCreateDialog(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          builder: ResponsiveBreakpointsConfig.builder,
          navigatorObservers: [navObserver],
          home: MultiBlocProvider(
            providers: [
              BlocProvider<CorrespondenceCubit>.value(value: listCubit),
              BlocProvider<SideMenuCubit>.value(value: sideMenuCubit),
            ],
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => MultiBlocProvider(
                          providers: [
                            BlocProvider<CorrespondenceCubit>.value(
                              value: listCubit,
                            ),
                            BlocProvider<SideMenuCubit>.value(
                              value: sideMenuCubit,
                            ),
                          ],
                          child: UpsertCorrespondenceInherited(
                            typeOperation: TypeOperation.create,
                            child: BlocProvider(
                              create: (_) => UpsertCorrespondenceCubit(
                                correspondenceRepository:
                                    correspondenceRepository,
                                organizationRepository:
                                    organizationRepository,
                              ),
                              child: const UpsertCorrespondenceView(),
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

    testWidgets('create abre formulario con catálogos', (tester) async {
      await pumpCreateDialog(tester);

      expect(find.text('Nueva correspondencia'), findsOneWidget);
      expect(find.text('Tipo de documento'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('INTERNAL oculta campos externos', (tester) async {
      await pumpCreateDialog(tester);

      expect(find.text('Remitente externo'), findsOneWidget);

      await _selectTypeDropdown(tester, optionText: 'Interna (CI)');

      expect(find.text('Remitente externo'), findsNothing);
    });

    testWidgets('error mantiene upsert abierto', (tester) async {
      correspondenceRepository.createResult =
          const Err(ServerFailure('No se pudo registrar'));

      await pumpCreateDialog(tester);
      await _fillMinimumExternalForm(tester);
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Nueva correspondencia'), findsOneWidget);
      expect(find.text('Error'), findsOneWidget);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Nueva correspondencia'), findsOneWidget);
    });

    testWidgets('success refresca list y muestra confirmación', (tester) async {
      await pumpCreateDialog(tester);
      await _fillMinimumExternalForm(tester);
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(listCubit.getCallCount, 1);
      expect(find.text('Registro exitoso'), findsOneWidget);
    });
  });
}

class _FakeListRepository implements repo.CorrespondenceRepository {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _fillMinimumExternalForm(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Solicitud externa');
  await _selectStringDropdown(tester, dropdownIndex: 0, optionText: 'Carta');
  await _selectStringDropdown(tester, dropdownIndex: 2, optionText: 'Sistemas');
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(3), 'Ciudadano');
}

Future<void> _selectStringDropdown(
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

Future<void> _selectTypeDropdown(
  WidgetTester tester, {
  required String optionText,
}) async {
  final dropdown =
      find.byType(DropdownButtonFormField<FormOption<CorrespondenceTypeCode>>);
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
