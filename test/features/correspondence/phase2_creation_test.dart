import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/auth/permissions.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/helpers/upsert_correspondence_inherited.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/views/upsert_correspondence_view.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/document_type_section.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/widgets/technical_report_fields.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

const comunicado = repo.DocumentType(
    id: 'c',
    code: 'COMUNICADO_INTERNO',
    name: 'Comunicado interno',
    profile: 'INTERNAL_COMMUNICATION',
    isOperational: true);
const informe = repo.DocumentType(
    id: 'i',
    code: 'INFORME',
    name: 'Informe',
    profile: 'REPORT',
    isOperational: true);
const memorandum = repo.DocumentType(
    id: 'm',
    code: 'MEMORANDUM',
    name: 'Memorándum',
    profile: 'MEMORANDUM',
    isOperational: true);
const circular = repo.DocumentType(
    id: 'r',
    code: 'CIRCULAR',
    name: 'Circular',
    profile: 'CIRCULAR',
    isOperational: true);

class CreationRepository extends Fake implements repo.CorrespondenceRepository {
  List<repo.DocumentType> catalog = [comunicado, informe];
  bool forbidden = false;
  repo.CreateCorrespondenceInput? input;
  @override
  Future<Result<bool, Failure>> getCreationPolicy() async => const Ok(false);
  @override
  Future<Result<List<repo.DocumentType>, Failure>> listDocumentTypes() async =>
      Ok(catalog);
  @override
  Future<Result<List<repo.EmployeeOption>, Failure>> listEmployees() async =>
      const Ok([repo.EmployeeOption(id: 'employee', fullName: 'Funcionario')]);
  @override
  Future<Result<List<repo.InstitutionalMayor>, Failure>>
      listEdieFirstRecipients() async => const Ok([]);
  @override
  Future<Result<repo.Correspondence, Failure>> createCorrespondence(
      repo.CreateCorrespondenceInput value) async {
    input = value;
    if (forbidden) {
      return const Err(
          ForbiddenFailure('Su jerarquía no permite crear este documento'));
    }
    return Ok(repo.Correspondence(
        id: 'doc',
        routeNumber: 'HR-2026-1',
        routeYear: 2026,
        routeSequence: 1,
        correspondenceType: value.correspondenceType,
        documentTypeCode: 'COMUNICADO_INTERNO',
        documentTypeName: 'Comunicado',
        subject: value.subject!,
        priority: value.priority,
        status: 'ACTIVE',
        registeredAt: DateTime.utc(2026),
        hasDocumentPdf: true));
  }
}

class Units extends Fake implements repo.OrganizationRepository {
  @override
  Future<Result<List<repo.OrganizationalUnit>, Failure>>
      listActiveUnits() async => const Ok(
          [repo.OrganizationalUnit(id: 'unit', code: 'U', name: 'Unidad')]);
}

UpsertCorrespondenceCubit createCubit(CreationRepository repository) =>
    UpsertCorrespondenceCubit(
        correspondenceRepository: repository, organizationRepository: Units());

void main() {
  test('legacy permission alone does not enable creation, new grants do', () {
    expect(canCreateCorrespondence(['correspondence.create']), isFalse);
    for (final permission in correspondenceCreationPermissions) {
      expect(canCreateCorrespondence([permission]), isTrue);
    }
  });
  for (final types in [
    [comunicado, informe],
    [comunicado, informe, memorandum],
    [comunicado, informe, memorandum, circular],
    <repo.DocumentType>[],
  ]) {
    testWidgets(
        'form shows exactly server-authorized catalog ${types.map((e) => e.code)}',
        (tester) async {
      final repository = CreationRepository()..catalog = types;
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
      if (types.isEmpty) {
        expect(find.byType(DocumentTypeSection), findsNothing);
        expect(find.textContaining('No tiene tipos documentales disponibles'),
            findsOneWidget);
      } else {
        final section = tester
            .widget<DocumentTypeSection>(find.byType(DocumentTypeSection));
        expect(section.documentTypes, types);
        expect(find.byType(TechnicalReportFields), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      inherited.dispose();
    });
  }
  testWidgets('refresh removes selected type that is no longer authorized',
      (tester) async {
    final repository = CreationRepository()..catalog = [circular];
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
    expect(inherited.documentType.get(), circular.id);
    repository.catalog = [comunicado, informe];
    await tester.tap(find.text('Actualizar tipos disponibles'));
    await tester.pumpAndSettle();
    expect(inherited.documentType.get(), comunicado.id);
    expect(find.text('CIRCULAR'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    inherited.dispose();
  });
  test(
      'refresh replaces catalog after permissions change including empty result',
      () async {
    final repository = CreationRepository()
      ..catalog = [comunicado, informe, memorandum, circular];
    final cubit = createCubit(repository);
    addTearDown(cubit.close);
    await cubit.init();
    expect(cubit.state.documentTypes.length, 4);
    repository.catalog = [comunicado, informe];
    await cubit.init();
    expect(cubit.state.documentTypes, [comunicado, informe]);
    repository.catalog = [];
    await cubit.init();
    expect(cubit.state.documentTypes, isEmpty);
  });
  for (final type in [comunicado, informe, memorandum, circular]) {
    test(
        'content profile ${type.code} sends internal payload and preserves routing',
        () async {
      final repository = CreationRepository();
      final cubit = createCubit(repository);
      addTearDown(cubit.close);
      await cubit.create(
          profile: resolveDocumentFormProfile(type.code, profile: type.profile),
          type: CorrespondenceTypeCode.ce,
          priorityLabel: 'Media',
          documentTypeId: type.id,
          initialToUnitId: 'unit',
          originEmployeeId: 'employee',
          subject: ' Asunto ',
          description: ' Contenido ',
          senderName: 'Ignored external field');
      expect(repository.input!.correspondenceType, 'INTERNAL');
      expect(repository.input!.description, 'Contenido');
      expect(repository.input!.senderName, isNull);
      expect(repository.input!.initialToUnitId, 'unit');
      expect(cubit.state.generalStatus, GeneralStatus.success);
    });
  }
  test('backend denial is displayed without successful creation', () async {
    final repository = CreationRepository()..forbidden = true;
    final cubit = createCubit(repository);
    addTearDown(cubit.close);
    await cubit.create(
        profile: DocumentFormProfile.circular,
        type: CorrespondenceTypeCode.ci,
        priorityLabel: 'Media',
        documentTypeId: 'r',
        initialToUnitId: 'unit',
        originEmployeeId: 'employee',
        subject: 'Asunto',
        description: 'Contenido');
    expect(cubit.state.generalStatus, GeneralStatus.error);
    expect(cubit.state.createdCorrespondence, isNull);
    expect(cubit.state.dialogMessage.message, contains('jerarquía'));
  });
  test('metadata profile and legacy aliases remain resolvable', () {
    expect(resolveDocumentFormProfile('RENAMED', profile: 'MEMORANDUM'),
        DocumentFormProfile.memorandum);
    expect(resolveDocumentFormProfile('EDIE'), DocumentFormProfile.chaining);
    expect(resolveDocumentFormProfile('S'), DocumentFormProfile.chaining);
    expect(
        resolveDocumentFormProfile('NOTA'), DocumentFormProfile.internalNote);
    expect(resolveDocumentFormProfile('CARTA'), DocumentFormProfile.generic);
  });
}
