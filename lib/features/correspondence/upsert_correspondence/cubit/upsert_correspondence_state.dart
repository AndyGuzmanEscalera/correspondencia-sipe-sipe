part of 'upsert_correspondence_cubit.dart';

class UpsertCorrespondenceState extends Equatable implements StatusState {
  const UpsertCorrespondenceState({
    this.documentTypes = const [],
    this.organizationalUnits = const [],
    this.employees = const [],
    this.unitUsers = const [],
    this.catalogLoaded = false,
    this.unitUsersLoading = false,
    this.defaultDocumentTypeId,
    this.institutionalMayor,
    this.institutionalMayorError,
    this.createdCorrespondence,
    this.attachmentUploadFailures = const [],
    this.dialogMessage = const DialogMessage.empty(),
    this.generalStatus = GeneralStatus.initial,
  });

  final List<repo.DocumentType> documentTypes;
  final List<repo.OrganizationalUnit> organizationalUnits;
  final List<repo.EmployeeOption> employees;
  final List<repo.UnitUser> unitUsers;
  final bool catalogLoaded;
  final bool unitUsersLoading;
  final String? defaultDocumentTypeId;
  final repo.InstitutionalMayor? institutionalMayor;
  final String? institutionalMayorError;
  final repo.Correspondence? createdCorrespondence;
  final List<String> attachmentUploadFailures;

  bool get hasBaseCatalog =>
      catalogLoaded &&
      documentTypes.isNotEmpty &&
      organizationalUnits.isNotEmpty;

  bool isCatalogReadyFor({
    required DocumentFormProfile profile,
    required bool isExternal,
  }) {
    if (!hasBaseCatalog) return false;
    if (profile == DocumentFormProfile.chaining && institutionalMayor == null) {
      return false;
    }
    if (!requiresOriginEmployee(profile: profile, isExternal: isExternal)) {
      return true;
    }
    return employees.isNotEmpty;
  }

  @override
  final DialogMessage dialogMessage;

  @override
  final GeneralStatus generalStatus;

  UpsertCorrespondenceState copyWith({
    List<repo.DocumentType>? documentTypes,
    List<repo.OrganizationalUnit>? organizationalUnits,
    List<repo.EmployeeOption>? employees,
    List<repo.UnitUser>? unitUsers,
    bool? catalogLoaded,
    bool? unitUsersLoading,
    String? defaultDocumentTypeId,
    repo.InstitutionalMayor? institutionalMayor,
    bool clearInstitutionalMayor = false,
    String? institutionalMayorError,
    repo.Correspondence? createdCorrespondence,
    bool clearCreatedCorrespondence = false,
    List<String>? attachmentUploadFailures,
    bool clearAttachmentUploadFailures = false,
    bool clearUnitUsers = false,
    DialogMessage? dialogMessage,
    GeneralStatus? generalStatus,
  }) {
    return UpsertCorrespondenceState(
      documentTypes: documentTypes ?? this.documentTypes,
      organizationalUnits: organizationalUnits ?? this.organizationalUnits,
      employees: employees ?? this.employees,
      unitUsers: clearUnitUsers ? const [] : (unitUsers ?? this.unitUsers),
      catalogLoaded: catalogLoaded ?? this.catalogLoaded,
      unitUsersLoading: unitUsersLoading ?? this.unitUsersLoading,
      defaultDocumentTypeId:
          defaultDocumentTypeId ?? this.defaultDocumentTypeId,
      institutionalMayor: clearInstitutionalMayor
          ? null
          : (institutionalMayor ?? this.institutionalMayor),
      institutionalMayorError:
          institutionalMayorError ?? this.institutionalMayorError,
      createdCorrespondence: clearCreatedCorrespondence
          ? null
          : (createdCorrespondence ?? this.createdCorrespondence),
      attachmentUploadFailures: clearAttachmentUploadFailures
          ? const []
          : (attachmentUploadFailures ?? this.attachmentUploadFailures),
      dialogMessage: dialogMessage ?? this.dialogMessage,
      generalStatus: generalStatus ?? this.generalStatus,
    );
  }

  @override
  List<Object?> get props => [
        documentTypes,
        organizationalUnits,
        employees,
        unitUsers,
        catalogLoaded,
        unitUsersLoading,
        defaultDocumentTypeId,
        institutionalMayor,
        institutionalMayorError,
        createdCorrespondence,
        attachmentUploadFailures,
        dialogMessage,
        generalStatus,
      ];
}
