part of 'configuration_cubit.dart';

class ConfigurationState extends Equatable implements StatusState {
  const ConfigurationState(
      {this.settings = const repo.InstitutionalSettings(),
      this.employees = const [],
      this.units = const [],
      this.intakeUnitId = '',
      this.recipientIds = const [],
      this.selectedEmployeeId = '',
      this.loaded = false,
      this.dialogMessage = const DialogMessage.empty(),
      this.generalStatus = GeneralStatus.initial});
  final repo.InstitutionalSettings settings;
  final List<repo.AuthorityEmployee> employees;
  final List<repo.OrganizationalUnit> units;
  final String intakeUnitId;
  final List<String> recipientIds;
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
          List<repo.OrganizationalUnit>? units,
          String? intakeUnitId,
          List<String>? recipientIds,
          String? selectedEmployeeId,
          bool? loaded,
          DialogMessage? dialogMessage,
          bool clearDialogMessage = false,
          GeneralStatus? generalStatus}) =>
      ConfigurationState(
          settings: settings ?? this.settings,
          employees: employees ?? this.employees,
          units: units ?? this.units,
          intakeUnitId: intakeUnitId ?? this.intakeUnitId,
          recipientIds: recipientIds ?? this.recipientIds,
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
        units,
        intakeUnitId,
        recipientIds,
        selectedEmployeeId,
        loaded,
        dialogMessage,
        generalStatus
      ];
}
