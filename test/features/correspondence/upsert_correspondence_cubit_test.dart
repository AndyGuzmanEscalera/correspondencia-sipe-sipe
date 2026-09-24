import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.createResult,
    this.listDocumentTypesResult,
  });

  Result<repo.Correspondence, Failure>? createResult;
  Result<List<repo.DocumentType>, Failure>? listDocumentTypesResult;
  repo.CreateCorrespondenceInput? lastCreateInput;

  @override
  Future<Result<repo.Correspondence, Failure>> createCorrespondence(
    repo.CreateCorrespondenceInput input,
  ) async {
    lastCreateInput = input;
    return createResult ??
        Ok(
          repo.Correspondence(
            id: 'corr-1',
            routeNumber: 'HR-2026-000001',
            routeYear: 2026,
            routeSequence: 1,
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
    return listDocumentTypesResult ??
        Ok([
          repo.DocumentType(id: 'dt-1', code: 'CARTA', name: 'Carta'),
        ]);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrganizationRepository implements repo.OrganizationRepository {
  _FakeOrganizationRepository({this.usersByUnit = const {}});

  final Map<String, List<repo.UnitUser>> usersByUnit;
  String? lastLoadedUnitId;

  @override
  Future<Result<List<repo.OrganizationalUnit>, Failure>>
      listActiveUnits() async {
    return Ok([
      repo.OrganizationalUnit(id: 'unit-1', code: 'SYS', name: 'Sistemas'),
      repo.OrganizationalUnit(id: 'unit-2', code: 'SEC', name: 'Secretaría'),
    ]);
  }

  @override
  Future<Result<List<repo.UnitUser>, Failure>> listUsersByUnit(
    String unitId,
  ) async {
    lastLoadedUnitId = unitId;
    return Ok(usersByUnit[unitId] ?? const []);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('UpsertCorrespondenceCubit', () {
    UpsertCorrespondenceCubit buildCubit({
      _FakeCorrespondenceRepository? correspondenceRepository,
      _FakeOrganizationRepository? organizationRepository,
    }) {
      return UpsertCorrespondenceCubit(
        correspondenceRepository:
            correspondenceRepository ?? _FakeCorrespondenceRepository(),
        organizationRepository:
            organizationRepository ?? _FakeOrganizationRepository(),
      );
    }

    test('init carga document types y units', () async {
      final cubit = buildCubit();

      await cubit.init();

      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.catalogReady, isTrue);
      expect(cubit.state.documentTypes, hasLength(1));
      expect(cubit.state.organizationalUnits, hasLength(2));
      await cubit.close();
    });

    test('loadUnitUsers carga usuarios de la unidad', () async {
      final organizationRepository = _FakeOrganizationRepository(
        usersByUnit: {
          'unit-2': [
            repo.UnitUser(
              id: 'user-2',
              username: 'dest',
              displayName: 'Usuario Destino',
            ),
          ],
        },
      );
      final cubit = buildCubit(organizationRepository: organizationRepository);

      await cubit.init();
      await cubit.loadUnitUsers('unit-2');

      expect(organizationRepository.lastLoadedUnitId, 'unit-2');
      expect(cubit.state.unitUsers.single.displayName, 'Usuario Destino');
      await cubit.close();
    });

    test('clearUnitUsers limpia usuarios destino', () async {
      final organizationRepository = _FakeOrganizationRepository(
        usersByUnit: {
          'unit-2': [
            repo.UnitUser(
              id: 'user-2',
              username: 'dest',
              displayName: 'Usuario Destino',
            ),
          ],
        },
      );
      final cubit = buildCubit(organizationRepository: organizationRepository);

      await cubit.init();
      await cubit.loadUnitUsers('unit-2');
      cubit.clearUnitUsers();

      expect(cubit.state.unitUsers, isEmpty);
      await cubit.close();
    });

    test('create EXTERNAL emite success con route number', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository();
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.create(
        subject: 'Solicitud externa',
        type: CorrespondenceTypeCode.ce,
        priorityLabel: 'Alta',
        documentTypeId: 'dt-1',
        initialToUnitId: 'unit-2',
        initialToUserId: 'user-2',
        initialInstruction: 'Atender',
        senderName: 'Ciudadano',
        senderDocument: '1234567',
        senderContact: '70000000',
        originDescription: 'Ventanilla',
      );

      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(
        cubit.state.dialogMessage.message,
        contains('HR-2026-000001'),
      );
      expect(cubit.state.createdCorrespondence?.id, 'corr-1');
      final input = correspondenceRepository.lastCreateInput!;
      expect(input.correspondenceType, 'EXTERNAL');
      expect(input.senderName, 'Ciudadano');
      expect(input.initialToUnitId, 'unit-2');
      await cubit.close();
    });

    test('create INTERNAL no envía campos externos', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository();
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.create(
        subject: 'Memorándum interno',
        type: CorrespondenceTypeCode.ci,
        priorityLabel: 'Media',
        documentTypeId: 'dt-1',
        initialToUnitId: 'unit-2',
        senderName: 'No debe ir',
      );

      final input = correspondenceRepository.lastCreateInput!;
      expect(input.correspondenceType, 'INTERNAL');
      expect(input.senderName, isNull);
      expect(input.senderDocument, isNull);
      expect(input.senderContact, isNull);
      expect(input.originDescription, isNull);
      await cubit.close();
    });

    test('create failure emite error funcional', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository(
        createResult: const Err(ServerFailure('No se pudo registrar')),
      );
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.create(
        subject: 'Fallará',
        type: CorrespondenceTypeCode.ce,
        priorityLabel: 'Baja',
        documentTypeId: 'dt-1',
        initialToUnitId: 'unit-2',
        senderName: 'Remitente',
      );

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'No se pudo registrar');
      await cubit.close();
    });

    test('init error en document types emite DialogMessage', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository(
        listDocumentTypesResult:
            const Err(ServerFailure('Error al cargar tipos')),
      );
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.init();

      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.catalogReady, isFalse);
      expect(cubit.state.generalStatus, GeneralStatus.error);
      await cubit.close();
    });
  });
}
