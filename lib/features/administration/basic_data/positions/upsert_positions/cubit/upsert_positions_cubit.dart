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

  Future<void> loadHierarchies() async {
    emit(state.copyWith(hierarchiesLoading: true, clearHierarchiesError: true));
    final result = await _repository.listHierarchies();
    if (isClosed) return;
    result.when(
      ok: (items) => emit(state.copyWith(
          hierarchies: items,
          hierarchiesLoading: false,
          clearHierarchiesError: true)),
      err: (failure) => emit(state.copyWith(
          hierarchiesLoading: false,
          hierarchiesError: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudieron cargar las jerarquías'))),
    );
  }

  Future<void> save({
    required String code,
    required String name,
    String? description,
    bool canViewUnitCorrespondence = false,
    String? hierarchyId,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.isEmpty || normalizedCode.length > 50) {
      emit(state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: const DialogMessage(
              title: 'Código inválido',
              message: 'Ingrese un código de 1 a 50 caracteres.')));
      return;
    }

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
        canViewUnitCorrespondence: canViewUnitCorrespondence,
        hierarchyId: hierarchyId,
        code: code.trim().toUpperCase(),
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
    String? code,
    required String name,
    String? description,
    bool? canViewUnitCorrespondence,
    String? hierarchyId,
    bool hierarchyChanged = false,
  }) async {
    final normalizedCode = (code ?? entity.code ?? '').trim().toUpperCase();
    if (normalizedCode.isEmpty || normalizedCode.length > 50) {
      emit(state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: const DialogMessage(
              title: 'Código inválido',
              message: 'Ingrese un código de 1 a 50 caracteres.')));
      return;
    }

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
        canViewUnitCorrespondence:
            canViewUnitCorrespondence ?? entity.canViewUnitCorrespondence,
        hierarchyId: hierarchyChanged ? hierarchyId : entity.hierarchyId,
        code: (code ?? entity.code ?? '').trim().toUpperCase(),
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
