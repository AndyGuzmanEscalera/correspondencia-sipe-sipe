import 'package:correspondencia_repository/correspondencia_repository.dart' as repo;
import 'package:correspondencia_sipe_sipe/core/helpers/dialog_message.dart';
import 'package:correspondencia_sipe_sipe/core/helpers/status_state.dart';
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:failures/failures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'configuration_state.dart';

class ConfigurationCubit extends Cubit<ConfigurationState> {
  ConfigurationCubit(this._repository) : super(const ConfigurationState());

  final repo.SystemSettingsAdminRepository _repository;

  Future<void> load() async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        clearDialogMessage: true,
      ),
    );

    final result = await _repository.getInstitutionalSettings();

    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudo cargar la configuración',
            ),
          ),
        ),
      );
      return;
    }

    final settings = result.valueOrNull()!;
    emit(
      state.copyWith(
        mayorDisplayName: settings.mayorDisplayName ?? '',
        generalStatus: GeneralStatus.success,
        loaded: true,
      ),
    );
  }

  Future<void> save(String mayorDisplayName) async {
    emit(
      state.copyWith(
        generalStatus: GeneralStatus.loading,
        dialogMessage: const DialogMessage(
          message: 'Guardando configuración...',
        ),
      ),
    );

    final trimmed = mayorDisplayName.trim();
    final result = await _repository.updateInstitutionalSettings(
      mayorDisplayName: trimmed.isEmpty ? null : trimmed,
    );

    if (result case Err(:final failure)) {
      emit(
        state.copyWith(
          generalStatus: GeneralStatus.error,
          dialogMessage: DialogMessage(
            title: 'Error',
            message: FailureGeneric.message(
              failure: failure,
              messageResult: 'No se pudo guardar la configuración',
            ),
          ),
        ),
      );
      return;
    }

    final settings = result.valueOrNull()!;
    emit(
      state.copyWith(
        mayorDisplayName: settings.mayorDisplayName ?? '',
        generalStatus: GeneralStatus.success,
        dialogMessage: const DialogMessage(
          title: 'Configuración guardada',
          message:
              'El nombre del alcalde/alcaldesa se aplicará en encadenamiento y PDF.',
        ),
      ),
    );
  }
}
