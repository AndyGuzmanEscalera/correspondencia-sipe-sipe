part of 'derive_correspondence_cubit.dart';

class DeriveCorrespondenceState extends Equatable implements StatusState {
  const DeriveCorrespondenceState({
    this.organizationalUnits = const [],
    this.unitUsers = const [],
    this.catalogLoaded = false,
    this.unitUsersLoading = false,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<repo.OrganizationalUnit> organizationalUnits;
  final List<repo.UnitUser> unitUsers;
  final bool catalogLoaded;
  final bool unitUsersLoading;

  bool get catalogReady =>
      catalogLoaded && organizationalUnits.isNotEmpty;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  DeriveCorrespondenceState copyWith({
    List<repo.OrganizationalUnit>? organizationalUnits,
    List<repo.UnitUser>? unitUsers,
    bool? catalogLoaded,
    bool? unitUsersLoading,
    bool clearUnitUsers = false,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return DeriveCorrespondenceState(
      organizationalUnits: organizationalUnits ?? this.organizationalUnits,
      unitUsers: clearUnitUsers ? const [] : (unitUsers ?? this.unitUsers),
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
      unitUsersLoading: unitUsersLoading ?? this.unitUsersLoading,
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        organizationalUnits,
        unitUsers,
        catalogLoaded,
        unitUsersLoading,
        dialogMessage,
        generalStatus,
      ];
}
