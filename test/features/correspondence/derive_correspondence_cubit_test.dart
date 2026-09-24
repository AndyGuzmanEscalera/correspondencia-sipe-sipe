import 'dart:async';

import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/derive_correspondence/cubit/derive_correspondence_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({this.deriveResult});

  Result<repo.Correspondence, Failure>? deriveResult;
  repo.DeriveCorrespondenceInput? lastDeriveInput;

  @override
  Future<Result<repo.Correspondence, Failure>> deriveCorrespondence(
    String correspondenceId,
    repo.DeriveCorrespondenceInput input,
  ) async {
    lastDeriveInput = input;
    return deriveResult ??
        Ok(
          repo.Correspondence(
            id: correspondenceId,
            routeNumber: 'HR-2026-000001',
            routeYear: 2026,
            routeSequence: 1,
            correspondenceType: 'INTERNAL',
            documentTypeCode: 'CARTA',
            documentTypeName: 'Carta',
            subject: 'Asunto',
            priority: 'MEDIUM',
            status: 'ACTIVE',
            registeredAt: DateTime.utc(2026, 1, 15),
          ),
        );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeOrganizationRepository implements repo.OrganizationRepository {
  _FakeOrganizationRepository({
    this.usersByUnit = const {},
    this.listActiveUnitsResult,
  });

  final Map<String, List<repo.UnitUser>> usersByUnit;
  Result<List<repo.OrganizationalUnit>, Failure>? listActiveUnitsResult;
  String? lastLoadedUnitId;

  @override
  Future<Result<List<repo.OrganizationalUnit>, Failure>>
      listActiveUnits() async {
    return listActiveUnitsResult ??
        Ok([
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
  group('DeriveCorrespondenceCubit', () {
    DeriveCorrespondenceCubit buildCubit({
      repo.CorrespondenceRepository? correspondenceRepository,
      _FakeOrganizationRepository? organizationRepository,
      String correspondenceId = 'corr-1',
    }) {
      return DeriveCorrespondenceCubit(
        correspondenceRepository:
            correspondenceRepository ?? _FakeCorrespondenceRepository(),
        organizationRepository:
            organizationRepository ?? _FakeOrganizationRepository(),
        correspondenceId: correspondenceId,
      );
    }

    test('init carga unidades activas', () async {
      final cubit = buildCubit();

      await cubit.init();

      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.catalogReady, isTrue);
      expect(cubit.state.organizationalUnits, hasLength(2));
      await cubit.close();
    });

    test('init error en units emite DialogMessage', () async {
      final organizationRepository = _FakeOrganizationRepository(
        listActiveUnitsResult:
            const Err(ServerFailure('Error al cargar unidades')),
      );
      final cubit = buildCubit(organizationRepository: organizationRepository);

      await cubit.init();

      expect(cubit.state.catalogLoaded, isTrue);
      expect(cubit.state.catalogReady, isFalse);
      expect(cubit.state.generalStatus, GeneralStatus.error);
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

    test('derive success emite GeneralStatus.success', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository();
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.derive(
        toUnitId: 'unit-2',
        toUserId: 'user-2',
        instruction: 'Atender',
        observation: 'Urgente',
      );

      expect(cubit.state.generalStatus, GeneralStatus.success);
      expect(
        cubit.state.dialogMessage.message,
        'La correspondencia fue derivada correctamente.',
      );
      final input = correspondenceRepository.lastDeriveInput!;
      expect(input.toUnitId, 'unit-2');
      expect(input.toUserId, 'user-2');
      expect(input.instruction, 'Atender');
      expect(input.observation, 'Urgente');
      await cubit.close();
    });

    test('derive omite campos opcionales vacíos', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository();
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.derive(toUnitId: 'unit-1');

      final input = correspondenceRepository.lastDeriveInput!;
      expect(input.toUserId, isNull);
      expect(input.instruction, isNull);
      expect(input.observation, isNull);
      await cubit.close();
    });

    test('derive failure emite error funcional', () async {
      final correspondenceRepository = _FakeCorrespondenceRepository(
        deriveResult: const Err(ServerFailure('No se pudo derivar')),
      );
      final cubit = buildCubit(
        correspondenceRepository: correspondenceRepository,
      );

      await cubit.derive(toUnitId: 'unit-2');

      expect(cubit.state.generalStatus, GeneralStatus.error);
      expect(cubit.state.dialogMessage.message, 'No se pudo derivar');
      await cubit.close();
    });

    test('derive loading usa mensaje operativo', () async {
      final gate = Completer<void>();
      final cubit = buildCubit(
        correspondenceRepository: _DelayedDeriveRepository(gate),
      );

      final future = cubit.derive(toUnitId: 'unit-2');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.generalStatus, GeneralStatus.loading);
      expect(
        cubit.state.dialogMessage.message,
        'Derivando correspondencia...',
      );

      gate.complete();
      await future;
      await cubit.close();
    });
  });
}

class _DelayedDeriveRepository implements repo.CorrespondenceRepository {
  _DelayedDeriveRepository(this.gate);

  final Completer<void> gate;

  @override
  Future<Result<repo.Correspondence, Failure>> deriveCorrespondence(
    String correspondenceId,
    repo.DeriveCorrespondenceInput input,
  ) async {
    await gate.future;
    return Ok(
      repo.Correspondence(
        id: correspondenceId,
        routeNumber: 'HR-2026-000001',
        routeYear: 2026,
        routeSequence: 1,
        correspondenceType: 'INTERNAL',
        documentTypeCode: 'CARTA',
        documentTypeName: 'Carta',
        subject: 'Asunto',
        priority: 'MEDIUM',
        status: 'ACTIVE',
        registeredAt: DateTime.utc(2026, 1, 15),
      ),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
