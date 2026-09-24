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
  });

  Result<repo.Correspondence, Failure>? detailResult;
  Result<List<repo.CorrespondenceMovement>, Failure>? movementsResult;
  int getCorrespondenceCallCount = 0;
  int listMovementsCallCount = 0;

  @override
  Future<Result<repo.Correspondence, Failure>> getCorrespondence(
    String id,
  ) async {
    getCorrespondenceCallCount++;
    return detailResult ??
        Ok(
          repo.Correspondence(
            id: id,
            routeNumber: 'HR-2026-000001',
            routeYear: 2026,
            routeSequence: 1,
            correspondenceType: 'INTERNAL',
            documentTypeCode: 'CARTA',
            documentTypeName: 'Carta',
            subject: 'Asunto de prueba',
            priority: 'MEDIUM',
            status: 'ACTIVE',
            registeredAt: DateTime.utc(2026, 1, 15),
          ),
        );
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
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CorrespondenceDetailCubit', () {
    test('init carga detail y movements', () async {
      final repository = _FakeCorrespondenceRepository();
      final cubit = CorrespondenceDetailCubit(
        repository: repository,
        correspondenceId: 'corr-1',
      );

      await cubit.init();

      expect(cubit.state.correspondence?.id, 'corr-1');
      expect(cubit.state.movements, hasLength(1));
      expect(repository.getCorrespondenceCallCount, 1);
      expect(repository.listMovementsCallCount, 1);
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

    test('state solo contiene detail y movements', () {
      const state = CorrespondenceDetailState();
      expect(state.correspondence, isNull);
      expect(state.movements, isEmpty);
      expect(state.generalStatus, GeneralStatus.initial);
    });
  });
}
