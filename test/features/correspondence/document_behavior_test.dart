import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/origin_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/route_sheet_fields.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/technical_report_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:failures/failures.dart';
import 'phase2_creation_test.dart' show CreationRepository, createCubit;

class RouteRepository extends CreationRepository {
  @override
  Future<Result<String, Failure>> getRouteSheetAuthority() async =>
      const Ok('Autoridad configurada');
}

void main() {
  for (final behavior in [
    repo.DocumentBehavior.routeSheet,
    repo.DocumentBehavior.report,
    repo.DocumentBehavior.memorandum,
    repo.DocumentBehavior.circular,
    repo.DocumentBehavior.internalCommunication,
    repo.DocumentBehavior.generic,
  ]) {
    testWidgets(
        'form uses backend behavior ${behavior.value} despite unrelated code',
        (tester) async {
      final repository = RouteRepository()
        ..catalog = [
          repo.DocumentType(
              id: 'custom',
              code: 'UNRELATED',
              name: 'Nombre libre',
              behavior: behavior,
              isOperational: true)
        ];
      final cubit = createCubit(repository);
      addTearDown(cubit.close);
      await cubit.init();
      final inherited = UpsertCorrespondenceInherited(
          typeOperation: TypeOperation.create,
          child: BlocProvider.value(
              value: cubit,
              child: const Scaffold(body: UpsertCorrespondenceBody())));
      inherited.clear();
      await tester.pumpWidget(MaterialApp(home: inherited));
      await tester.pumpAndSettle();
      if (behavior == repo.DocumentBehavior.routeSheet) {
        expect(find.byType(RouteSheetFields), findsOneWidget);
        expect(find.text('PARA: Autoridad configurada'), findsOneWidget);
        for (final label in [
          'Referencia',
          'Texto / contenido',
        ]) {
          expect(find.text(label), findsOneWidget);
        }
        expect(find.byKey(const Key('route-sheet-automatic-issuance')),
            findsOneWidget);
        for (final label in [
          'Número de hojas',
          'Fecha de emisión (AAAA-MM-DD)',
          'Hora de emisión (HH:MM)',
        ]) {
          expect(find.text(label), findsNothing);
        }
      } else if (behavior == repo.DocumentBehavior.generic) {
        expect(find.byType(TechnicalReportFields), findsNothing);
        expect(find.text('Asunto'), findsOneWidget);
      } else {
        expect(find.byType(TechnicalReportFields), findsOneWidget);
        expect(find.text('Descripción / contenido'), findsOneWidget);
        expect(find.byType(RouteSheetFields), findsNothing);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      inherited.dispose();
    });
  }
  for (final external in [true, false]) {
    testWidgets('route sheet DE ${external ? "free name" : "employee"}',
        (tester) async {
      final inherited = UpsertCorrespondenceInherited(
          typeOperation: TypeOperation.create,
          child: Scaffold(
              body: SingleChildScrollView(
                  child: OriginSection(
            profile: DocumentBehavior.routeSheet,
            isExternal: external,
            employees: const [
              repo.EmployeeOption(id: 'e', fullName: 'Funcionario')
            ],
            onTypeChanged: (_) {},
          ))));
      inherited.clear();
      await tester.pumpWidget(MaterialApp(home: inherited));
      expect(find.text(external ? 'DE: nombre libre' : 'DE: funcionario'),
          findsOneWidget);
      expect(find.text(external ? 'DE: funcionario' : 'DE: nombre libre'),
          findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
      inherited.dispose();
    });
    test('route payload includes ${external ? "name only" : "employee only"}',
        () async {
      final repository = RouteRepository();
      final cubit = createCubit(repository);
      addTearDown(cubit.close);
      await cubit.create(
          profile: DocumentBehavior.routeSheet,
          type:
              external ? CorrespondenceTypeCode.ce : CorrespondenceTypeCode.ci,
          priorityLabel: 'Media',
          documentTypeId: 'route',
          initialToUnitId: 'u',
          subject: 'Referencia',
          reference: 'REF',
          description: ' Contenido ',
          originEmployeeId: 'e',
          senderName: ' Ciudadano ');
      final input = repository.input!;
      expect(input.originEmployeeId, external ? null : 'e');
      expect(input.senderName, external ? 'Ciudadano' : null);
      expect(input.description, 'Contenido');
      expect(input.emissionDate, isNull);
      expect(input.emissionTime, isNull);
      expect(input.pageCount, isNull);
    });
  }
}
