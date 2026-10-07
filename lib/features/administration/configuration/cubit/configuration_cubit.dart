import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
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

  void _error(Failure failure, String fallback) => emit(state.copyWith(
      generalStatus: GeneralStatus.error,
      dialogMessage: DialogMessage(
          title: 'Error',
          message: FailureGeneric.message(
              failure: failure, messageResult: fallback))));

  Future<void> load({bool canManage = false}) async {
    emit(state.copyWith(
        generalStatus: GeneralStatus.loading,
        loaded: false,
        clearDialogMessage: true));
    final result = await _repository.getInstitutionalSettings();
    if (result case Err(:final failure)) {
      _error(failure, 'No se pudo cargar la configuración');
      return;
    }
    final settings = result.valueOrNull()!;
    var employees = <repo.AuthorityEmployee>[];
    if (canManage) {
      final choices = await _repository.getAuthorityEmployees();
      if (choices case Err(:final failure)) {
        _error(failure, 'No se pudieron cargar los funcionarios disponibles');
        return;
      }
      employees = choices.valueOrNull()!;
    }
    emit(state.copyWith(
        settings: settings,
        employees: employees,
        selectedEmployeeId: settings.mayorEmployeeId ?? '',
        loaded: true,
        generalStatus: GeneralStatus.success));
  }

  void selectMayor(repo.AuthorityEmployee employee) {
    emit(state.copyWith(selectedEmployeeId: employee.employeeId));
  }

  Future<void> save() async {
    if (!state.loaded || state.generalStatus == GeneralStatus.loading) return;
    emit(state.copyWith(
        generalStatus: GeneralStatus.loading, clearDialogMessage: true));
    final result = await _repository.updateInstitutionalSettings(
        mayorEmployeeId:
            state.selectedEmployeeId.isEmpty ? null : state.selectedEmployeeId);
    if (result case Err(:final failure)) {
      _error(failure, 'No se pudo guardar la configuración');
      return;
    }
    final settings = result.valueOrNull()!;
    emit(state.copyWith(
        settings: settings,
        selectedEmployeeId: settings.mayorEmployeeId ?? '',
        generalStatus: GeneralStatus.success,
        dialogMessage: const DialogMessage(
            title: 'Configuración guardada',
            message:
                'La autoridad institucional se aplicará a los nuevos documentos EDIE.')));
  }
}
