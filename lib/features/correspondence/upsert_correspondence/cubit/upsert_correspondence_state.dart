part of 'upsert_correspondence_cubit.dart';

class UpsertCorrespondenceState extends Equatable implements StatusState {
  const UpsertCorrespondenceState({
    this.documentTypes = const [],
    this.organizationalUnits = const [],
    this.unitUsers = const [],
    this.catalogLoaded = false,
    this.unitUsersLoading = false,
    this.createdCorrespondence,
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<repo.DocumentType> documentTypes;
  final List<repo.OrganizationalUnit> organizationalUnits;
  final List<repo.UnitUser> unitUsers;
  final bool catalogLoaded;
  final bool unitUsersLoading;
  final repo.Correspondence? createdCorrespondence;

  bool get catalogReady =>
      catalogLoaded &&
      documentTypes.isNotEmpty &&
      organizationalUnits.isNotEmpty;

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UpsertCorrespondenceState copyWith({
    List<repo.DocumentType>? documentTypes,
    List<repo.OrganizationalUnit>? organizationalUnits,
    List<repo.UnitUser>? unitUsers,
    bool? catalogLoaded,
    bool? unitUsersLoading,
    repo.Correspondence? createdCorrespondence,
    bool clearCreatedCorrespondence = false,
    bool clearUnitUsers = false,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return UpsertCorrespondenceState(
      documentTypes: documentTypes ?? this.documentTypes,
      organizationalUnits:
          organizationalUnits ?? this.organizationalUnits,
      unitUsers: clearUnitUsers ? const [] : (unitUsers ?? this.unitUsers),
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
      unitUsersLoading: unitUsersLoading ?? this.unitUsersLoading,
      createdCorrespondence: clearCreatedCorrespondence
          ? null
          : (createdCorrespondence ?? this.createdCorrespondence),
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        documentTypes,
        organizationalUnits,
        unitUsers,
        catalogLoaded,
        unitUsersLoading,
        createdCorrespondence,
        dialogMessage,
        generalStatus,
      ];
}
