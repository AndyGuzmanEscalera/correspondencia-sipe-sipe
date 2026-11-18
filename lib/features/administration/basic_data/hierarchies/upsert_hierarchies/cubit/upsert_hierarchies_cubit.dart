import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'upsert_hierarchies_state.dart';

class UpsertHierarchiesCubit extends Cubit<UpsertHierarchiesState> {
  UpsertHierarchiesCubit(this._repository)
      : super(const UpsertHierarchiesState());
  final repo.HierarchiesAdminRepository _repository;
  Future<void> save(
      {repo.PositionHierarchy? entity,
      required String code,
      required String name,
      required int rank}) async {
    if (state.generalStatus == GeneralStatus.loading) return;
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty ||
        normalized.length > 50 ||
        name.trim().isEmpty ||
        name.trim().length > 200 ||
        rank < 1 ||
        rank > 1000000) {
      emit(state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: const DialogMessage(
              title: 'Datos inválidos',
              message:
                  'Revise código, nombre y nivel jerárquico (1 a 1000000).')));
      return;
    }
    emit(state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(message: 'Guardando jerarquía...')));
    final input =
        repo.HierarchyInput(code: normalized, name: name.trim(), rank: rank);
    final result = entity == null
        ? await _repository.create(input)
        : await _repository.update(entity.id, input);
    if (isClosed) return;
    result.when(
        ok: (_) => emit(state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
                title: 'Éxito', message: 'Jerarquía guardada correctamente.'))),
        err: (failure) => emit(state.copyWith(
            generalStatus: GeneralStatus.error,
            dialogMessage: DialogMessage(
                title: 'Error',
                message: FailureGeneric.message(
                    failure: failure,
                    messageResult: 'No se pudo guardar la jerarquía.')))));
  }
}
