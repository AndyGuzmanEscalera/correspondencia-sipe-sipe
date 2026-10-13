import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list_correspondence/cubit/correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/cubit/side_menu_cubit.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:correspondencia_sipe_sipe/shared/widgets/app_form_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_helpers/app_dropdown_test_helpers.dart';

class _TrackingCorrespondenceCubit extends CorrespondenceCubit {
  _TrackingCorrespondenceCubit(super.repository);

  int getCallCount = 0;

  @override
  Future<void> get() async {
    getCallCount++;
  }
}

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  @override
  Future<Result<bool, Failure>> getCreationPolicy() async => const Ok(false);
  _FakeCorrespondenceRepository({this.createResult});

  Result<repo.Correspondence, Failure>? createResult;
  Completer<void>? createGate;
  int createCalls = 0;
  repo.CreateCorrespondenceInput? receivedInput;
  bool missingAuthority = false;

  @override
  Future<Result<repo.Correspondence, Failure>> createCorrespondence(
    repo.CreateCorrespondenceInput input,
  ) async {
    createCalls++;
    receivedInput = input;
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
            subject: input.subject ?? '',
            priority: input.priority,
            status: 'ACTIVE',
            registeredAt: DateTime.utc(2026, 1, 15),
          ),
        );
  }

  @override
  Future<Result<List<repo.DocumentType>, Failure>> listDocumentTypes() async {
    return Ok([
      repo.DocumentType(id: 'dt-edie', code: 'EDIE', name: 'Encadenamiento'),
    ]);
  }

  @override
  Future<Result<List<repo.EmployeeOption>, Failure>> listEmployees() async {
    return Ok([
      repo.EmployeeOption(
        id: 'emp-1',
        fullName: 'Juan Pérez',
        unitName: 'Sistemas',
      ),
    ]);
  }

  @override
  Future<Result<List<repo.InstitutionalMayor>, Failure>>
      listEdieFirstRecipients() async {
    if (missingAuthority) {
      return const Err(ValidationFailure(
          'No se pudieron cargar los receptores iniciales configurados.'));
    }
    return Ok([
      const repo.InstitutionalMayor(
        userId: 'mayor-user',
        employeeId: 'mayor-emp',
        unitId: 'unit-mayor',
        employeeName: 'Jaime Montero López',
        positionName: 'Secretario Municipal Administrativo',
        unitName: 'Secretaría Municipal Administrativa',
        paraLabel: 'Secretaría — Jaime Montero López',
      ),
      const repo.InstitutionalMayor(
        userId: 'technical-user',
        employeeId: 'technical-emp',
        unitId: 'technical-unit',
        employeeName: 'Secretario Técnico',
        positionName: 'Secretario Municipal Técnico',
        unitName: 'Secretaría Municipal Técnica',
        paraLabel: 'Secretario Técnico',
      ),
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
  Future<Result<bool, Failure>> getCreationPolicy() async => const Ok(false);
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
  Future<Result<List<repo.EmployeeOption>, Failure>> listEmployees() async {
    return const Ok([]);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAuthRepository implements repo.AuthenticationRepository {
  @override
  Future<Result<repo.UserSession, Failure>> currentUser() async {
    return const Ok(
      repo.UserSession(
        id: 'user-1',
        username: 'tester',
        isActive: true,
      ),
    );
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
      getIt.registerFactoryParam<CorrespondenceDetailCubit, String, String?>(
        (correspondenceId, viewerUnitId) => CorrespondenceDetailCubit(
          repository: _FakeDetailCorrespondenceRepository(),
          correspondenceId: correspondenceId,
          viewerUnitId: viewerUnitId,
        ),
      );
      if (getIt.isRegistered<CorrespondenceDocumentActionsCubit>()) {
        getIt.unregister<CorrespondenceDocumentActionsCubit>();
      }
      getIt.registerFactoryParam<CorrespondenceDocumentActionsCubit, String,
          void>(
        (correspondenceId, _) => CorrespondenceDocumentActionsCubit(
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
      if (getIt.isRegistered<CorrespondenceDocumentActionsCubit>()) {
        getIt.unregister<CorrespondenceDocumentActionsCubit>();
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
              builder: (ownerContext) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () {
                      showDialog<void>(
                        context: ownerContext,
                        builder: (dialogContext) => MultiBlocProvider(
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
                                organizationRepository: organizationRepository,
                              ),
                              child: UpsertCorrespondenceView(
                                hostDialogContext: dialogContext,
                                ownerContext: ownerContext,
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

    testWidgets('create abre formulario con catálogos', (tester) async {
      await pumpCreateDialog(tester);

      expect(find.text('Nueva correspondencia'), findsOneWidget);
      expect(find.text('Tipo de documento'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'EDIE registra un solo receptor y no muestra segundo destinatario',
        (tester) async {
      await pumpCreateDialog(tester);
      expect(find.text('Primer destinatario'), findsOneWidget);
      expect(find.text('Receptor inicial'), findsOneWidget);
      expect(find.text('Segundo destinatario'), findsNothing);
      await _fillMinimumExternalForm(tester);
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();
      expect(correspondenceRepository.createCalls, 1);
    });

    testWidgets('Ventanilla elige secretario Técnico como primer destinatario',
        (tester) async {
      await pumpCreateDialog(tester);
      await _fillMinimumExternalForm(tester,
          firstRecipient: 'Secretario Técnico');
      await tester.tap(find.text('Registrar'));
      await tester.pumpAndSettle();
      expect(correspondenceRepository.receivedInput!.firstRecipientEmployeeId,
          'technical-emp');
      expect(correspondenceRepository.receivedInput!.initialToUserId,
          'technical-user');
    });

    testWidgets('EDIE sin autoridad muestra validación y no registra',
        (tester) async {
      correspondenceRepository.missingAuthority = true;
      await pumpCreateDialog(tester);
      expect(
          find.text(
              'No se pudieron cargar los receptores iniciales configurados.'),
          findsOneWidget);
      expect(correspondenceRepository.createCalls, 0);
      expect(
          tester
              .widget<AppFormDialog>(find.byType(AppFormDialog))
              .isSubmitDisabled,
          isTrue);
    });

    testWidgets('INTERNAL oculta campos externos en encadenamiento', (
      tester,
    ) async {
      await pumpCreateDialog(tester);

      expect(find.text('Remitente externo'), findsOneWidget);

      await _selectTypeDropdown(tester, optionText: 'Interna (CI)');

      expect(find.text('Remitente externo'), findsNothing);
      expect(find.text('Empleado origen'), findsOneWidget);
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

    testWidgets('mobile 390x844 renderiza sin overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpCreateDialog(tester);

      expect(find.text('Nueva correspondencia'), findsOneWidget);
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(tester.takeException(), isNull);
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

    testWidgets('success cierra diálogo de creación al confirmar',
        (tester) async {
      await pumpCreateDialog(tester);
      await _fillMinimumExternalForm(tester);
      await tester.tap(find.text('Registrar'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Registro exitoso'), findsOneWidget);
      expect(find.text('Nueva correspondencia'), findsNothing);
    });

    testWidgets(
      'EDIE externa sin asunto ni referencia muestra error y no crea',
      (tester) async {
        correspondenceRepository.createCalls = 0;

        await pumpCreateDialog(tester);
        await _fillExternalFormWithoutSubject(tester);
        await tester.tap(find.text('Registrar'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(
          find.text(
            UpsertCorrespondenceInherited.chainingSubjectReferenceError,
          ),
          findsWidgets,
        );
        expect(correspondenceRepository.createCalls, 0);
        expect(find.text('Nueva correspondencia'), findsOneWidget);
        expect(find.text('Registrando correspondencia...'), findsNothing);

        correspondenceRepository.createGate = Completer<void>();

        await tester.enterText(
          find.byType(TextFormField).at(4),
          'Solicitud externa',
        );
        await tester.tap(find.text('Registrar'));
        await tester.pump();

        expect(correspondenceRepository.createCalls, 1);
        expect(find.byType(CircularProgressIndicator), findsWidgets);

        correspondenceRepository.createGate!.complete();
        await tester.pumpAndSettle();

        expect(find.text('Registro exitoso'), findsOneWidget);
      },
    );
  });
}

class _FakeListRepository implements repo.CorrespondenceRepository {
  @override
  Future<Result<bool, Failure>> getCreationPolicy() async => const Ok(false);
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _fillMinimumExternalForm(WidgetTester tester,
    {String firstRecipient = 'Jaime Montero López'}) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Ciudadano');
  await tester.enterText(find.byType(TextFormField).at(4), 'Solicitud externa');
  if (find.text('Receptor inicial').evaluate().isNotEmpty) {
    await selectAppDropdownOption(tester,
        dropdownIndex: 3,
        optionText: firstRecipient,
        scrollable: find.byType(Scrollable).first);
  }
}

Future<void> _fillExternalFormWithoutSubject(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Ciudadano');
  await tester.scrollUntilVisible(
    find.text('Asunto'),
    48,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  if (find.text('Receptor inicial').evaluate().isNotEmpty) {
    await selectAppDropdownOption(tester,
        dropdownIndex: 3,
        optionText: 'Jaime Montero López',
        scrollable: find.byType(Scrollable).first);
  }
}

Future<void> _selectTypeDropdown(
  WidgetTester tester, {
  required String optionText,
}) async {
  await tester.scrollUntilVisible(
    find.text('Tipo de correspondencia'),
    48,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await selectAppDropdownOption(
    tester,
    dropdownIndex: 2,
    optionText: optionText,
    scrollable: find.byType(Scrollable).first,
  );
}
