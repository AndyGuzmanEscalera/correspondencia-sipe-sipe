import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/detail/cubit/correspondence_detail_cubit.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCorrespondenceRepository implements repo.CorrespondenceRepository {
  _FakeCorrespondenceRepository({
    this.detailResult,
    this.movementsResult,
    this.concludeResult,
    this.reopenResult,
  });

  Result<repo.Correspondence, Failure>? detailResult;
  Result<List<repo.CorrespondenceMovement>, Failure>? movementsResult;
  Result<repo.Correspondence, Failure>? concludeResult;
  Result<repo.Correspondence, Failure>? reopenResult;
  int getCorrespondenceCallCount = 0;
  int listMovementsCallCount = 0;
  int listEmployeesCallCount = 0;
  bool concluded = false;

  repo.Correspondence _detail(String id) => repo.Correspondence(
        id: id,
        routeNumber: 'HR-2026-000001',
        routeYear: 2026,
        routeSequence: 1,
        correspondenceType: 'INTERNAL',
        documentTypeCode: 'CARTA',
        documentTypeName: 'Carta',
        subject: 'Asunto de prueba',
        priority: 'MEDIUM',
        status: concluded ? 'CONCLUDED' : 'ACTIVE',
        registeredAt: DateTime.utc(2026, 1, 15),
      );

  @override
  Future<Result<repo.Correspondence, Failure>> getCorrespondence(
    String id,
  ) async {
    getCorrespondenceCallCount++;
    return detailResult ?? Ok(_detail(id));
  }

  @override
  Future<Result<List<repo.CorrespondenceMovement>, Failure>> listMovements(
    String correspondenceId,
  ) async {
    listMovementsCallCount++;
    return movementsResult ??
        Ok([
          repo.CorrespondenceMovement(
            id: 'mov-1',
            sequenceNumber: 1,
            movementType: 'CREATED',
            toUnitName: 'Sistemas',
            createdByUsername: 'admin',
            createdAt: DateTime.utc(2026, 1, 15),
          ),
        ]);
  }

  @override
  Future<Result<List<repo.EmployeeOption>, Failure>> listEmployees() async {
    listEmployeesCallCount++;
    return const Ok([]);
  }

  @override
  Future<Result<repo.Correspondence, Failure>> concludeCorrespondence(
    String id,
    repo.CorrespondenceLifecycleInput input,
  ) async {
    if (concludeResult != null) {
      return concludeResult!;
    }
    concluded = true;
    return Ok(_detail(id));
  }

  @override
  Future<Result<repo.Correspondence, Failure>> reopenCorrespondence(
    String id,
    repo.CorrespondenceLifecycleInput input,
  ) async {
    if (reopenResult != null) {
      return reopenResult!;
    }
    concluded = false;
    return Ok(_detail(id));
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CorrespondenceDetailCubit', () {
    test('init carga detail y movements', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceDetailCubit(
        repository: repository,
        correspondenceId: 'corr-1',
        viewerUnitId: 'unit-1',
      );

      await cubit.init();

      expect(cubit.state.correspondence?.id, 'corr-1');
      expect(cubit.state.movements, hasLength(1));
      expect(cubit.state.viewerUnitId, 'unit-1');
      expect(repository.getCorrespondenceCallCount, 1);
      expect(repository.listMovementsCallCount, 1);
      expect(repository.listEmployeesCallCount, 0);
      await cubit.close();
    });

    test('refresh recarga detail y movements', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceDetailCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.init();
      await cubit.refresh();

      expect(repository.getCorrespondenceCallCount, 2);
      expect(repository.listMovementsCallCount, 2);
      await cubit.close();
    });

    test('init error en detail emite GeneralStatus.error', () async {
      final repository = _FakeCorrespondenceRepository(
        detailResult: const Err(ServerFailure('No se encontró')),
      );
      final cubit = CorrespondenceDetailCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.init();

      expect(cubit.state.generalStatus, GeneralStatus.initial);
      expect(cubit.state.dialogMessage.message, 'No se encontró');
      expect(cubit.state.correspondence, isNull);
      await cubit.close();
    });

    test('conclude success refresca detail', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceDetailCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.init();
      await cubit.conclude(observation: 'Listo');

      expect(cubit.state.correspondence?.status, 'CONCLUDED');
      expect(cubit.state.lifecycleActionInProgress, isFalse);
      expect(repository.getCorrespondenceCallCount, greaterThan(1));
      await cubit.close();
    });

    test('conclude error preserva correspondencia y libera acción', () async {
      final repository = _FakeCorrespondenceRepository(
        concludeResult: const Err(ServerFailure('Transición inválida')),
      );
      final cubit = CorrespondenceDetailCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.init();
      final statusBefore = cubit.state.correspondence?.status;

      await cubit.conclude(observation: 'x');

      expect(cubit.state.lifecycleActionInProgress, isFalse);
      expect(cubit.state.generalStatus, GeneralStatus.initial);
      expect(cubit.state.dialogMessage.title, 'Error');
      expect(cubit.state.correspondence?.status, statusBefore);
      expect(cubit.state.correspondence?.status, 'ACTIVE');
      await cubit.close();
    });

    test('reopen error preserva correspondencia y libera acción', () async {
      final repository = _FakeCorrespondenceRepository(
        reopenResult: const Err(ServerFailure('No autorizado')),
      );
      repository.concluded = true;
      final cubit = CorrespondenceDetailCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.init();
      final statusBefore = cubit.state.correspondence?.status;

      await cubit.reopen(observation: 'x');

      expect(cubit.state.lifecycleActionInProgress, isFalse);
      expect(cubit.state.generalStatus, GeneralStatus.initial);
      expect(cubit.state.dialogMessage.title, 'Error');
      expect(cubit.state.correspondence?.status, statusBefore);
      expect(cubit.state.correspondence?.status, 'CONCLUDED');
      await cubit.close();
    });

    test('state solo contiene detail y movements', () {
      const state = CorrespondenceDetailState();
      expect(state.correspondence, isNull);
      expect(state.movements, isEmpty);
      expect(state.generalStatus, GeneralStatus.initial);
    });
  });
}
