import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/list/cubit/correspondence_list_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.createResult,
    this.listResult,
  });

  Result<repo.Correspondence, Failure>? createResult;
  Result<repo.CorrespondencePage, Failure>? listResult;
  repo.CreateCorrespondenceInput? lastCreateInput;
  int? lastListPage;
  int? lastListPageSize;

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
    return Ok([
      repo.DocumentType(id: 'dt-1', code: 'CARTA', name: 'Carta'),
    ]);
  }

  @override
  Future<Result<repo.CorrespondencePage, Failure>> listCorrespondences({
    int page = 1,
    int pageSize = 20,
    String? search,
    String? status,
    String? correspondenceType,
  }) async {
    lastListPage = page;
    lastListPageSize = pageSize;
    return listResult ??
        Ok(
          repo.CorrespondencePage(
            items: const [],
            page: page,
            pageSize: pageSize,
            total: 0,
            totalPages: 0,
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
  group('CorrespondenceListCubit create', () {
    test('maps EXTERNAL payload with destination fields', () async {
      final correspondenceRepo = _FakeCorrespondenceRepository();
      final organizationRepo = _FakeOrganizationRepository();
      final cubit = CorrespondenceListCubit(
        repository: correspondenceRepo,
        organizationRepository: organizationRepo,
      );

      await cubit.init();

      final success = await cubit.create(
        const CreateCorrespondenceFormData(
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
        ),
      );

      expect(success, isTrue);
      final input = correspondenceRepo.lastCreateInput!;
      expect(input.correspondenceType, 'EXTERNAL');
      expect(input.senderName, 'Ciudadano');
      expect(input.initialToUnitId, 'unit-2');
      expect(input.initialToUserId, 'user-2');
      expect(input.initialInstruction, 'Atender');
      expect(input.originDescription, 'Ventanilla');
    });

    test('maps INTERNAL payload without external sender fields', () async {
      final correspondenceRepo = _FakeCorrespondenceRepository();
      final organizationRepo = _FakeOrganizationRepository();
      final cubit = CorrespondenceListCubit(
        repository: correspondenceRepo,
        organizationRepository: organizationRepo,
      );

      await cubit.init();

      final success = await cubit.create(
        const CreateCorrespondenceFormData(
          subject: 'Memorándum interno',
          type: CorrespondenceTypeCode.ci,
          priorityLabel: 'Media',
          documentTypeId: 'dt-1',
          initialToUnitId: 'unit-2',
        ),
      );

      expect(success, isTrue);
      final input = correspondenceRepo.lastCreateInput!;
      expect(input.correspondenceType, 'INTERNAL');
      expect(input.senderName, isNull);
      expect(input.senderDocument, isNull);
      expect(input.senderContact, isNull);
      expect(input.originDescription, isNull);
    });

    test('create failure keeps modal flow by returning false', () async {
      final correspondenceRepo = _FakeCorrespondenceRepository(
        createResult: const Err(ServerFailure('No se pudo registrar')),
      );
      final organizationRepo = _FakeOrganizationRepository();
      final cubit = CorrespondenceListCubit(
        repository: correspondenceRepo,
        organizationRepository: organizationRepo,
      );

      await cubit.init();

      final success = await cubit.create(
        const CreateCorrespondenceFormData(
          subject: 'Fallará',
          type: CorrespondenceTypeCode.ce,
          priorityLabel: 'Baja',
          documentTypeId: 'dt-1',
          initialToUnitId: 'unit-2',
          senderName: 'Remitente',
        ),
      );

      expect(success, isFalse);
      expect(cubit.state.createInProgress, isFalse);
    });

    test('loadCreateUnitUsers reloads users for selected unit', () async {
      final organizationRepo = _FakeOrganizationRepository(
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
      final cubit = CorrespondenceListCubit(
        repository: _FakeCorrespondenceRepository(),
        organizationRepository: organizationRepo,
      );

      await cubit.init();
      await cubit.loadCreateUnitUsers('unit-2');

      expect(organizationRepo.lastLoadedUnitId, 'unit-2');
      expect(cubit.state.createUnitUsers.single.displayName, 'Usuario Destino');
    });

    test('resetCreateDestinationUsers clears selected users', () async {
      final organizationRepo = _FakeOrganizationRepository(
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
      final cubit = CorrespondenceListCubit(
        repository: _FakeCorrespondenceRepository(),
        organizationRepository: organizationRepo,
      );

      await cubit.init();
      await cubit.loadCreateUnitUsers('unit-2');
      cubit.resetCreateDestinationUsers();

      expect(cubit.state.createUnitUsers, isEmpty);
    });
  });

  group('CorrespondenceListCubit pagination', () {
    test('changePage requests the selected page from repository', () async {
      final correspondenceRepo = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceListCubit(
        repository: correspondenceRepo,
        organizationRepository: _FakeOrganizationRepository(),
      );

      await cubit.init();
      await cubit.changePage(3);

      expect(correspondenceRepo.lastListPage, 3);
      expect(cubit.state.page, 3);
    });

    test('changePageSize resets to first page with new size', () async {
      final correspondenceRepo = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceListCubit(
        repository: correspondenceRepo,
        organizationRepository: _FakeOrganizationRepository(),
      );

      await cubit.init();
      await cubit.changePage(2);
      await cubit.changePageSize(50);

      expect(correspondenceRepo.lastListPage, 1);
      expect(correspondenceRepo.lastListPageSize, 50);
      expect(cubit.state.page, 1);
      expect(cubit.state.pageSize, 50);
    });

    test('filter resets search to page 1', () async {
      final correspondenceRepo = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceListCubit(
        repository: correspondenceRepo,
        organizationRepository: _FakeOrganizationRepository(),
      );

      await cubit.init();
      await cubit.changePage(2);
      cubit.filter('HR-2026');
      await Future<void>.delayed(const Duration(milliseconds: 400));

      expect(correspondenceRepo.lastListPage, 1);
      expect(cubit.state.query, 'HR-2026');
    });
  });
}
