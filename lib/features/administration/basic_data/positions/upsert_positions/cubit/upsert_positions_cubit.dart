import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'upsert_positions_state.dart';

class UpsertPositionsCubit extends Cubit<UpsertPositionsState> {
  UpsertPositionsCubit(this._repository) : super(const UpsertPositionsState());

  final repo.PositionsAdminRepository _repository;

  Future<void> save({
    required String code,
    required String name,
    String? description,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Registrando cargo...',
        ),
      ),
    );

    final result = await _repository.create(
      repo.PositionInput(
        code: code.trim(),
        name: name.trim(),
        description: _optional(description),
      ),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Cargo registrado correctamente.',
            ),
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'Error al registrar cargo',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> update({
    required repo.PositionAdmin entity,
    required String name,
    String? description,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Actualizando cargo...',
        ),
      ),
    );

    final result = await _repository.update(
      entity.id,
      repo.PositionInput(
        code: entity.code ?? '',
        name: name.trim(),
        description: _optional(description),
      ),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Cargo actualizado correctamente.',
            ),
          ),
        );
      },
      err: (failure) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
              title: 'Error',
              message: FailureGeneric.message(
                failure: failure,
                messageResult: 'Error al actualizar cargo',
              ),
            ),
          ),
        );
      },
    );
  }

  String? _optional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
