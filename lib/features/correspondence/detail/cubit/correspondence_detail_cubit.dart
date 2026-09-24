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
    required String correspondenceId,
  })  : _repository = repository,
        _correspondenceId = correspondenceId,
        super(const CorrespondenceDetailState());

  final repo.CorrespondenceRepository _repository;
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
        generalStatus: GeneralStatus.initial,
        dialogMessage: const DialogMessage.empty(),
      ),
    );
  }
}
