part of 'configuration_cubit.dart';

class ConfigurationState extends Equatable implements StatusState {
  const ConfigurationState(
      {this.settings = const repo.InstitutionalSettings(),
      this.employees = const [],
      this.selectedEmployeeId = '',
      this.loaded = false,
      this.dialogMessage = const DialogMessage.empty(),
      this.generalStatus = GeneralStatus.initial});
  final repo.InstitutionalSettings settings;
  final List<repo.AuthorityEmployee> employees;
  final String selectedEmployeeId;
  final bool loaded;
  @override
  final DialogMessage dialogMessage;
  @override
  final GeneralStatus generalStatus;
  repo.AuthorityEmployee? get selectedMayor {
    for (final item in employees) {
      if (item.employeeId == selectedEmployeeId) return item;
    }
    return settings.mayor?.employeeId == selectedEmployeeId
        ? settings.mayor
        : null;
  }

  ConfigurationState copyWith(
          {repo.InstitutionalSettings? settings,
          List<repo.AuthorityEmployee>? employees,
          String? selectedEmployeeId,
          bool? loaded,
          DialogMessage? dialogMessage,
          bool clearDialogMessage = false,
          GeneralStatus? generalStatus}) =>
      ConfigurationState(
          settings: settings ?? this.settings,
          employees: employees ?? this.employees,
          selectedEmployeeId: selectedEmployeeId ?? this.selectedEmployeeId,
          loaded: loaded ?? this.loaded,
          dialogMessage: clearDialogMessage
              ? const DialogMessage.empty()
              : dialogMessage ?? this.dialogMessage,
          generalStatus: generalStatus ?? this.generalStatus);
  @override
  List<Object?> get props => [
        settings,
        employees,
        selectedEmployeeId,
        loaded,
        dialogMessage,
        generalStatus
      ];
}
