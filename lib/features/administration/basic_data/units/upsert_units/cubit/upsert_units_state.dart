part of 'upsert_units_cubit.dart';

class UpsertUnitsState extends Equatable implements StatusState {
  const UpsertUnitsState({
    this.parentUnits = const [],
    this.catalogLoaded = false,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<repo.OrganizationalUnitAdmin> parentUnits;
  final bool catalogLoaded;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UpsertUnitsState copyWith({
    List<repo.OrganizationalUnitAdmin>? parentUnits,
    bool? catalogLoaded,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return UpsertUnitsState(
      parentUnits: parentUnits ?? this.parentUnits,
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        parentUnits,
        catalogLoaded,
        dialogMessage,
        generalStatus,
      ];
}
