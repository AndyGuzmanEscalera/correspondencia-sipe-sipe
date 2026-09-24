part of 'upsert_employees_cubit.dart';

class UpsertEmployeesState extends Equatable implements StatusState {
  const UpsertEmployeesState({
    this.units = const [],
    this.positions = const [],
    this.catalogLoaded = false,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<repo.OrganizationalUnitAdmin> units;
  final List<repo.PositionAdmin> positions;
  final bool catalogLoaded;

  bool get catalogReady =>
      catalogLoaded && units.isNotEmpty && positions.isNotEmpty;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UpsertEmployeesState copyWith({
    List<repo.OrganizationalUnitAdmin>? units,
    List<repo.PositionAdmin>? positions,
    bool? catalogLoaded,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return UpsertEmployeesState(
      units: units ?? this.units,
      positions: positions ?? this.positions,
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        units,
        positions,
        catalogLoaded,
        dialogMessage,
        generalStatus,
      ];
}
