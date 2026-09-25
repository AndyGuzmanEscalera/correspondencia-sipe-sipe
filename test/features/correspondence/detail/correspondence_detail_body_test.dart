import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/attachments/cubit/correspondence_attachments_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/cubit/derive_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/helpers/derive_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/views/derive_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/views/correspondence_detail_body.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_info_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_movements_section.dart';
import 'package:correspondencia_sipe_sipe/injection/injection_bloc.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'detail_test_fixtures.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  @override
  Future<Result<List<repo.CorrespondenceAttachment>, Failure>>
      listAttachments(String correspondenceId) async {
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
        employeeId: 'emp-1',
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
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CorrespondenceDetailBody', () {
    late CorrespondenceDetailCubit cubit;
    late _FakeOrganizationRepository organizationRepository;

    setUp(() {
      organizationRepository = _FakeOrganizationRepository();
      cubit = CorrespondenceDetailCubit(
        repository: _FakeCorrespondenceRepository(),
        authRepository: _FakeAuthRepository(),
        correspondenceId: 'corr-1',
      );
      cubit.emit(
        cubit.state.copyWith(
          correspondence: externalCorrespondence,
          movements: [vigenteMovement],
          viewerUnitId: 'unit-sistemas',
        ),
      );

      if (getIt.isRegistered<DeriveCorrespondenceCubit>()) {
        getIt.unregister<DeriveCorrespondenceCubit>();
      }
      if (getIt.isRegistered<CorrespondenceAttachmentsCubit>()) {
        getIt.unregister<CorrespondenceAttachmentsCubit>();
      }
      if (getIt.isRegistered<CorrespondenceDocumentActionsCubit>()) {
        getIt.unregister<CorrespondenceDocumentActionsCubit>();
      }
      getIt.registerFactoryParam<DeriveCorrespondenceCubit, String, void>(
        (correspondenceId, _) => DeriveCorrespondenceCubit(
          correspondenceRepository: _FakeCorrespondenceRepository(),
          organizationRepository: organizationRepository,
          correspondenceId: correspondenceId,
        ),
      );
      getIt.registerFactoryParam<CorrespondenceAttachmentsCubit, String, void>(
        (correspondenceId, _) => CorrespondenceAttachmentsCubit(
          repository: _FakeCorrespondenceRepository(),
          correspondenceId: correspondenceId,
        ),
      );
      getIt.registerFactoryParam<CorrespondenceDocumentActionsCubit, String, void>(
        (correspondenceId, _) => CorrespondenceDocumentActionsCubit(
          repository: _FakeCorrespondenceRepository(),
          correspondenceId: correspondenceId,
        ),
      );
    });

    tearDown(() async {
      await cubit.close();
      if (getIt.isRegistered<DeriveCorrespondenceCubit>()) {
        getIt.unregister<DeriveCorrespondenceCubit>();
      }
      if (getIt.isRegistered<CorrespondenceAttachmentsCubit>()) {
        getIt.unregister<CorrespondenceAttachmentsCubit>();
      }
      if (getIt.isRegistered<CorrespondenceDocumentActionsCubit>()) {
        getIt.unregister<CorrespondenceDocumentActionsCubit>();
      }
    });

    Future<void> pumpBody(
      WidgetTester tester, {
      Size size = const Size(900, 1200),
      bool settle = true,
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          builder: ResponsiveBreakpointsConfig.builder,
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: MultiBlocProvider(
                providers: [
                  BlocProvider<CorrespondenceDetailCubit>.value(value: cubit),
                  BlocProvider(
                    create: (_) => getIt<CorrespondenceDocumentActionsCubit>(
                      param1: 'corr-1',
                    ),
                  ),
                ],
                child: const CorrespondenceDetailBody(
                  correspondenceId: 'corr-1',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      if (settle) {
        await tester.pumpAndSettle();
      }
    }

    testWidgets('ACTIVE autorizado muestra Concluir y no Reabrir', (
      tester,
    ) async {
      await pumpBody(tester);

      expect(find.text('Concluir'), findsOneWidget);
      expect(find.text('Reabrir'), findsNothing);
    });

    testWidgets('ACTIVE sin autorización oculta Derivar y Concluir', (
      tester,
    ) async {
      cubit.emit(
        cubit.state.copyWith(
          correspondence: externalCorrespondence,
          movements: [vigenteMovement],
          viewerUnitId: 'unit-otra',
        ),
      );
      await pumpBody(tester);

      expect(find.text('Concluir'), findsNothing);
      expect(find.text('Derivar trámite'), findsNothing);
    });

    testWidgets('muestra info, adjuntos, movements y derive', (tester) async {
      await pumpBody(tester);

      expect(find.byType(CorrespondenceInfoSection), findsOneWidget);
      expect(find.text('Adjuntos'), findsOneWidget);
      expect(find.text('Agregar archivos'), findsOneWidget);
      expect(find.text('Ver encadenamiento'), findsOneWidget);
      expect(find.text('Hoja de Ruta'), findsOneWidget);
      expect(find.byType(CorrespondenceMovementsSection), findsOneWidget);
      expect(find.byType(DeriveCorrespondencePage), findsOneWidget);
      expect(find.text('Derivar trámite'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('no contiene controllers de derive embebidos en Detail', (
      tester,
    ) async {
      await pumpBody(tester);

      expect(find.byType(DeriveCorrespondenceInherited), findsOneWidget);
      expect(find.text('Unidad destino'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('loading cuando correspondence es null', (tester) async {
      cubit.emit(const CorrespondenceDetailState());

      await pumpBody(tester, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CorrespondenceInfoSection), findsNothing);
    });

    testWidgets('INFORME no muestra acción Encadenamiento', (tester) async {
      cubit.emit(
        cubit.state.copyWith(
          correspondence: internalCorrespondence,
          movements: [vigenteMovement],
        ),
      );

      await pumpBody(tester, size: const Size(1366, 900));

      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
      expect(tester.takeException(), isNull);
    });

    group('responsive', () {
      Future<void> expectDetailWithoutOverflow(
        WidgetTester tester,
        Size size,
      ) async {
        await pumpBody(tester, size: size);

        expect(find.text('Detalle de correspondencia'), findsOneWidget);
        expect(find.text('Movimientos'), findsOneWidget);
        expect(find.text('Derivar trámite'), findsOneWidget);
        expect(find.text('Adjuntos'), findsOneWidget);
        expect(find.text('Agregar archivos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      testWidgets('390x844 sin overflow y con scroll mobile', (tester) async {
        await expectDetailWithoutOverflow(tester, const Size(390, 844));

        expect(
          find.byKey(CorrespondenceDetailBody.contentScrollKey),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
        expect(find.text('Unidad destino'), findsOneWidget);

        await tester.drag(
          find.byKey(CorrespondenceDetailBody.contentScrollKey),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();

        expect(find.text('Movimientos'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('430x932 sin overflow', (tester) async {
        await expectDetailWithoutOverflow(tester, const Size(430, 932));
        expect(
          find.byKey(CorrespondenceDetailBody.contentScrollKey),
          findsOneWidget,
        );
        expect(find.text('Unidad destino'), findsOneWidget);
      });

      testWidgets('768x1024 sin overflow layout desktop', (tester) async {
        await expectDetailWithoutOverflow(tester, const Size(768, 1024));
        expect(
          find.byKey(CorrespondenceDetailBody.contentScrollKey),
          findsOneWidget,
        );
        expect(find.text('Unidad destino'), findsOneWidget);
      });

      testWidgets('1024x768 sin overflow layout desktop', (tester) async {
        await expectDetailWithoutOverflow(tester, const Size(1024, 768));
        expect(find.text('Ver encadenamiento'), findsOneWidget);
        expect(
          find.byKey(CorrespondenceDetailBody.contentScrollKey),
          findsOneWidget,
        );
        expect(find.text('Unidad destino'), findsOneWidget);
      });

      testWidgets('1366x768 sin overflow layout desktop', (tester) async {
        await expectDetailWithoutOverflow(tester, const Size(1366, 768));
        expect(find.text('Ver encadenamiento'), findsOneWidget);
        expect(
          find.byKey(CorrespondenceDetailBody.contentScrollKey),
          findsOneWidget,
        );
        expect(find.text('Unidad destino'), findsOneWidget);
      });

      testWidgets('1366x900 sin overflow layout desktop', (tester) async {
        await expectDetailWithoutOverflow(tester, const Size(1366, 900));
        expect(find.text('Ver encadenamiento'), findsOneWidget);
        expect(
          find.byKey(CorrespondenceDetailBody.contentScrollKey),
          findsOneWidget,
        );
        expect(find.text('Unidad destino'), findsOneWidget);
      });
    });
  });
}
