import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/presentation/widget/responsive_breakpoints.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_document_actions_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/widgets/correspondence_detail_header.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'detail_test_fixtures.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  int downloadCalls = 0;

  @override
  Future<Result<List<int>, Failure>> downloadChainingPdf(
    String correspondenceId,
  ) async {
    downloadCalls++;
    return const Ok([1, 2, 3]);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CorrespondenceDetailHeader', () {
    Future<void> pumpHeader(
      WidgetTester tester,
      Widget child, {
      Size surfaceSize = const Size(1200, 800),
    }) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          builder: ResponsiveBreakpointsConfig.builder,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('EDIE muestra acción Ver PDF', (tester) async {
      await pumpHeader(
        tester,
        BlocProvider(
          create: (_) => CorrespondenceDocumentActionsCubit(
            repository: _FakeCorrespondenceRepository(),
            correspondenceId: externalCorrespondence.id,
          ),
          child: CorrespondenceDetailHeader(
            item: externalCorrespondence,
            onBack: () {},
          ),
        ),
      );

      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    });

    testWidgets('codigo completo real muestra Ver PDF y Descargar PDF',
        (tester) async {
      const code = 'ENCADENAMIENTO DE DOCUMENTOS INTERNOS Y EXTERNOS';
      final document = CorrespondenceEntity(
          id: 'real',
          uniqueNumber: 1,
          year: 2026,
          cite: '',
          routeNumber: 'HR-2026-000001',
          type: CorrespondenceTypeCode.ce,
          priority: 'Media',
          subject: 'test',
          registeredAt: DateTime(2026, 10, 15),
          status: 'ACTIVE',
          statusLabel: 'Activa',
          documentTypeCode: code,
          documentTypeName: code);
      await pumpHeader(
          tester,
          BlocProvider(
              create: (_) => CorrespondenceDocumentActionsCubit(
                  repository: _FakeCorrespondenceRepository(),
                  correspondenceId: document.id),
              child:
                  CorrespondenceDetailHeader(item: document, onBack: () {})));
      expect(find.text('Ver PDF').hitTestable(), findsOneWidget);
      expect(find.text('Descargar PDF').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('INFORME oculta acción de encadenamiento', (tester) async {
      await pumpHeader(
        tester,
        BlocProvider(
          create: (_) => CorrespondenceDocumentActionsCubit(
            repository: _FakeCorrespondenceRepository(),
            correspondenceId: internalCorrespondence.id,
          ),
          child: CorrespondenceDetailHeader(
            item: internalCorrespondence,
            onBack: () {},
          ),
        ),
      );

      expect(find.text('Ver PDF'), findsNothing);
    });

    testWidgets('NOTA oculta acción de encadenamiento', (tester) async {
      await pumpHeader(
        tester,
        BlocProvider(
          create: (_) => CorrespondenceDocumentActionsCubit(
            repository: _FakeCorrespondenceRepository(),
            correspondenceId: notaCorrespondence.id,
          ),
          child: CorrespondenceDetailHeader(
            item: notaCorrespondence,
            onBack: () {},
          ),
        ),
      );

      expect(find.text('Ver PDF'), findsNothing);
    });

    testWidgets('click EDIE solicita PDF al cubit', (tester) async {
      final repository = _FakeCorrespondenceRepository();
      late CorrespondenceDocumentActionsCubit cubit;
      await pumpHeader(
        tester,
        BlocProvider(
          create: (_) => cubit = CorrespondenceDocumentActionsCubit(
            repository: repository,
            correspondenceId: externalCorrespondence.id,
          ),
          child: CorrespondenceDetailHeader(
            item: externalCorrespondence,
            onBack: () {},
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
      await tester.pumpAndSettle();

      expect(repository.downloadCalls, 1);
      expect(cubit.state.openingChainingPdf, isFalse);
      await cubit.close();
    });
  });
}
