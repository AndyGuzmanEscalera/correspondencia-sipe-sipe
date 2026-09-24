import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/cubit/derive_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/helpers/derive_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/views/derive_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
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
        correspondenceId: 'corr-1',
      );
      cubit.emit(
        cubit.state.copyWith(
          correspondence: externalCorrespondence,
          movements: [vigenteMovement],
        ),
      );

      if (getIt.isRegistered<DeriveCorrespondenceCubit>()) {
        getIt.unregister<DeriveCorrespondenceCubit>();
      }
      getIt.registerFactoryParam<DeriveCorrespondenceCubit, String, void>(
        (correspondenceId, _) => DeriveCorrespondenceCubit(
          correspondenceRepository: _FakeCorrespondenceRepository(),
          organizationRepository: organizationRepository,
          correspondenceId: correspondenceId,
        ),
      );
    });

    tearDown(() async {
      await cubit.close();
      if (getIt.isRegistered<DeriveCorrespondenceCubit>()) {
        getIt.unregister<DeriveCorrespondenceCubit>();
      }
    });

    Future<void> pumpBody(
      WidgetTester tester, {
      Size size = const Size(900, 1200),
    }) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          builder: ResponsiveBreakpointsConfig.builder,
          home: Scaffold(
            body: BlocProvider<CorrespondenceDetailCubit>.value(
              value: cubit,
              child: const CorrespondenceDetailBody(
                correspondenceId: 'corr-1',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets('muestra info, movements y derive', (tester) async {
      await pumpBody(tester);

      expect(find.byType(CorrespondenceInfoSection), findsOneWidget);
      expect(find.byType(CorrespondenceMovementsSection), findsOneWidget);
      expect(find.byType(DeriveCorrespondencePage), findsOneWidget);
      expect(find.text('Derivar trámite'), findsOneWidget);
    });

    testWidgets('no contiene controllers de derive embebidos en Detail', (
      tester,
    ) async {
      await pumpBody(tester);

      expect(find.byType(DeriveCorrespondenceInherited), findsOneWidget);
      expect(find.text('Unidad destino'), findsOneWidget);
    });

    testWidgets('loading cuando correspondence es null', (tester) async {
      cubit.emit(const CorrespondenceDetailState());

      await pumpBody(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(CorrespondenceInfoSection), findsNothing);
    });

    testWidgets('usable en mobile 390px', (tester) async {
      await pumpBody(tester, size: const Size(390, 900));

      expect(find.text('Detalle de correspondencia'), findsOneWidget);
      expect(find.text('Solicitud externa'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
