import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/mappers/correspondence_entity_mapper.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'correspondence_detail_state.dart';

class CorrespondenceDetailCubit extends Cubit<CorrespondenceDetailState> {
  CorrespondenceDetailCubit({
    required repo.CorrespondenceRepository repository,
    required repo.AuthenticationRepository authRepository,
    required String correspondenceId,
  })  : _repository = repository,
        _authRepository = authRepository,
        _correspondenceId = correspondenceId,
        super(const CorrespondenceDetailState());

  final repo.CorrespondenceRepository _repository;
  final repo.AuthenticationRepository _authRepository;
  final String _correspondenceId;

  String get correspondenceId => _correspondenceId;

  Future<void> init() async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Cargando detalle...'),
      ),
    );

    await refresh();
  }

  Future<void> refresh() async {
    await _loadDetail();
  }

  Future<void> conclude({String? observation}) async {
    if (state.lifecycleActionInProgress) return;

    emit(
      state.copyWith(
        lifecycleActionInProgress: true,
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Concluyendo correspondencia...',
        ),
      ),
    );

    final result = await _repository.concludeCorrespondence(
      _correspondenceId,
      repo.CorrespondenceLifecycleInput(observation: observation),
    );

    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          lifecycleActionInProgress: false,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudo concluir la correspondencia',
            ),
          ),
        ),
      );
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.initial,
          lifecycleActionInProgress: false,
        ),
      );
      return;
    }

    await _loadDetail();
    emit(
      state.copyWith(
        lifecycleActionInProgress: false,
        generalStatus: GeneralStatus.success,
        dialogMessage: const DialogMessage(
          title: 'Correspondencia concluida',
          message: 'El trámite fue marcado como concluido.',
        ),
      ),
    );
  }

  Future<void> reopen({String? observation}) async {
    if (state.lifecycleActionInProgress) return;

    emit(
      state.copyWith(
        lifecycleActionInProgress: true,
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Reabriendo correspondencia...',
        ),
      ),
    );

    final result = await _repository.reopenCorrespondence(
      _correspondenceId,
      repo.CorrespondenceLifecycleInput(observation: observation),
    );

    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          lifecycleActionInProgress: false,
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudo reabrir la correspondencia',
            ),
          ),
        ),
      );
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.initial,
          lifecycleActionInProgress: false,
        ),
      );
      return;
    }

    await _loadDetail();
    emit(
      state.copyWith(
        lifecycleActionInProgress: false,
        generalStatus: GeneralStatus.success,
        dialogMessage: const DialogMessage(
          title: 'Correspondencia reabierta',
          message: 'El trámite volvió a estado activo.',
        ),
      ),
    );
  }

  Future<void> _loadDetail() async {
    final detailResult = await _repository.getCorrespondence(_correspondenceId);
    if (detailResult case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'Error al cargar el detalle',
            ),
          ),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    final movementsResult =
        await _repository.listMovements(_correspondenceId);
    if (movementsResult case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'Error al cargar los movimientos',
            ),
          ),
        ),
      );
      emit(state.copyWith(generalStatus: GeneralStatus.initial));
      return;
    }

    final viewerUnitId = await _resolveViewerUnitId();

    final detail = detailResult.valueOrNull()!.toUiEntity();
    final movements = movementsResult
            .valueOrNull()
            ?.map((item) => item.toUiEntity())
            .toList() ??
        const <CorrespondenceMovementEntity>[];

    emit(
      state.copyWith(
        correspondence: detail,
        movements: movements,
        viewerUnitId: viewerUnitId,
        generalStatus: GeneralStatus.initial,
        dialogMessage: const DialogMessage.empty(),
      ),
    );
  }

  Future<String?> _resolveViewerUnitId() async {
    final userResult = await _authRepository.currentUser();
    final employeeId = userResult.valueOrNull()?.employeeId;
    if (employeeId == null || employeeId.isEmpty) {
      return null;
    }

    final employeesResult = await _repository.listEmployees();
    if (employeesResult case Err()) {
      return null;
    }

    for (final employee in employeesResult.valueOrNull() ?? const []) {
      if (employee.id == employeeId) {
        return employee.unitId;
      }
    }
    return null;
  }
}
