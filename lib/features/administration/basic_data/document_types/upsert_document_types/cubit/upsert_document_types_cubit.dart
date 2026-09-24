import 'package:correspondencia_repository/correspondencia_repository.dart' as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'upsert_document_types_state.dart';

class UpsertDocumentTypesCubit extends Cubit<UpsertDocumentTypesState> {
  UpsertDocumentTypesCubit(this._repository) : super(const UpsertDocumentTypesState());

  final repo.DocumentTypesAdminRepository _repository;

  Future<void> save({
    required String code,
    required String name,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Registrando tipo de documento...',
        ),
      ),
    );

    final result = await _repository.create(
      repo.DocumentTypeInput(code: code.trim(), name: name.trim()),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Tipo de documento registrado correctamente.',
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
                messageResult: 'Error al registrar tipo de documento',
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> update({
    required String name,
    required repo.DocumentTypeAdmin entity,
  }) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Actualizando tipo de documento...',
        ),
      ),
    );

    final result = await _repository.update(
      entity.id,
      repo.DocumentTypeUpdateInput(name: name.trim()),
    );

    result.when(
      ok: (_) {
        emit(
          state.copyWith(
            generalStatus: GeneralStatus.success,
            dialogMessage: const DialogMessage(
              title: 'Éxito',
              message: 'Tipo de documento actualizado correctamente.',
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
                messageResult: 'Error al actualizar tipo de documento',
              ),
            ),
          ),
        );
      },
    );
  }
}
