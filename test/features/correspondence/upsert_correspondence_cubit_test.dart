import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/document_type_profiles.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/cubit/upsert_correspondence_cubit.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/upsert_correspondence/models/pending_attachment.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.createResult,
    this.listDocumentTypesResult,
    this.uploadResult,
  });

  Result<repo.Correspondence, Failure>? createResult;
  Result<List<repo.DocumentType>, Failure>? listDocumentTypesResult;
  Result<repo.CorrespondenceAttachment, Failure>? uploadResult;
  repo.CreateCorrespondenceInput? lastCreateInput;
  int uploadCalls = 0;

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
            documentTypeCode: 'EDIE',
            documentTypeName: 'Encadenamiento',
            subject: input.subject ?? input.description ?? '',
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
          repo.DocumentType(id: 'dt-edie', code: 'EDIE', name: 'Encadenamiento'),
          repo.DocumentType(id: 'dt-nota', code: 'NOTA', name: 'Nota Interna'),
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
  Future<Result<repo.CorrespondenceAttachment, Failure>> uploadAttachment({
    required String correspondenceId,
    required repo.UploadAttachmentInput input,
  }) async {
    uploadCalls++;
    return uploadResult ??
        Ok(
          repo.CorrespondenceAttachment(
            id: 'att-$uploadCalls',
            correspondenceId: correspondenceId,
            originalFilename: input.filename,
            isActive: true,
            createdByUserId: 'user-1',
            createdAt: DateTime.utc(2026, 1, 15),
          ),
        );
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

    test('init carga document types, units y employees', () async {
      final cubit = buildCubit();

      await cubit.init();

      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.hasBaseCatalog, isTrue);
      expect(
        cubit.state.isCatalogReadyFor(
          profile: DocumentFormProfile.chaining,
          isExternal: true,
        ),
        isTrue,
      );
      expect(cubit.state.documentTypes, hasLength(2));
      expect(cubit.state.organizationalUnits, hasLength(2));
      expect(cubit.state.employees, hasLength(1));
      expect(cubit.state.defaultDocumentTypeId, 'dt-edie');
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

    test('create CHAINING EXTERNAL emite success', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository();
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.create(
        profile: DocumentFormProfile.chaining,
        subject: 'Solicitud externa',
        type: CorrespondenceTypeCode.ce,
        priorityLabel: 'Alta',
        documentTypeId: 'dt-edie',
        initialToUnitId: 'unit-2',
        senderName: 'Ciudadano',
      );

      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(cubit.state.createdCorrespondence?.id, 'corr-1');
      final input = correspondenceRepository.lastCreateInput!;
      expect(input.correspondenceType, 'EXTERNAL');
      expect(input.senderName, 'Ciudadano');
      await cubit.close();
    });

    test('create INTERNAL NOTE envía description y origin_employee_id', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository();
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.create(
        profile: DocumentFormProfile.internalNote,
        description: 'Contenido de la nota',
        type: CorrespondenceTypeCode.ci,
        priorityLabel: 'Media',
        documentTypeId: 'dt-nota',
        initialToUnitId: 'unit-2',
        originEmployeeId: 'emp-1',
      );

      final input = correspondenceRepository.lastCreateInput!;
      expect(input.correspondenceType, 'INTERNAL');
      expect(input.description, 'Contenido de la nota');
      expect(input.originEmployeeId, 'emp-1');
      expect(input.senderName, isNull);
      await cubit.close();
    });

    test('create sube adjuntos pendientes secuencialmente', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository();
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.create(
        profile: DocumentFormProfile.chaining,
        subject: 'Con adjuntos',
        type: CorrespondenceTypeCode.ce,
        priorityLabel: 'Baja',
        documentTypeId: 'dt-edie',
        initialToUnitId: 'unit-2',
        senderName: 'Remitente',
        pendingAttachments: const [
          PendingAttachment(filename: 'a.pdf', bytes: [1]),
          PendingAttachment(filename: 'b.pdf', bytes: [2, 3]),
        ],
      );

      expect(correspondenceRepository.uploadCalls, 2);
      expect(cubit.state.generalStatus, GeneralStatus.success);
      await cubit.close();
    });

    test('create con fallo parcial de adjuntos informa en mensaje', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository(
        uploadResult: const Err(ServerFailure('Error al subir')),
      );
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.create(
        profile: DocumentFormProfile.chaining,
        subject: 'Parcial',
        type: CorrespondenceTypeCode.ce,
        priorityLabel: 'Baja',
        documentTypeId: 'dt-edie',
        initialToUnitId: 'unit-2',
        senderName: 'Remitente',
        pendingAttachments: const [
          PendingAttachment(filename: 'a.pdf', bytes: [1]),
        ],
      );

      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(cubit.state.attachmentUploadFailures, hasLength(1));
      expect(cubit.state.dialogMessage.title, 'Registro parcial');
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
        profile: DocumentFormProfile.chaining,
        subject: 'Fallará',
        type: CorrespondenceTypeCode.ce,
        priorityLabel: 'Baja',
        documentTypeId: 'dt-edie',
        initialToUnitId: 'unit-2',
        senderName: 'Remitente',
      );

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'No se pudo registrar');
      await cubit.close();
    });
  });
}
