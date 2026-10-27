class MeInstitutionalUnitResponse {
  const MeInstitutionalUnitResponse({
    required this.id,
    required this.name,
  });

  factory MeInstitutionalUnitResponse.fromJson(Map<String, dynamic> json) {
    return MeInstitutionalUnitResponse(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
}

class MeInstitutionalHierarchyResponse {
  const MeInstitutionalHierarchyResponse(
      {required this.id,
      required this.code,
      required this.name,
      required this.rank,
      required this.isActive});
  factory MeInstitutionalHierarchyResponse.fromJson(
          Map<String, dynamic> json) =>
      MeInstitutionalHierarchyResponse(
          id: json['id'] as String,
          code: json['code'] as String,
          name: json['name'] as String,
          rank: json['rank'] as int,
          isActive: json['is_active'] as bool);
  final String id;
  final String code;
  final String name;
  final int rank;
  final bool isActive;
}

class MeInstitutionalPositionResponse {
  const MeInstitutionalPositionResponse({
    this.hierarchy,
    required this.id,
    required this.name,
  });

  factory MeInstitutionalPositionResponse.fromJson(Map<String, dynamic> json) {
    return MeInstitutionalPositionResponse(
      hierarchy: json['hierarchy'] == null
          ? null
          : MeInstitutionalHierarchyResponse.fromJson(
              json['hierarchy'] as Map<String, dynamic>),
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
  final MeInstitutionalHierarchyResponse? hierarchy;
}

class MeEmployeeContextResponse {
  const MeEmployeeContextResponse({
    required this.id,
    required this.fullName,
    this.documentNumber,
    this.position,
    this.unit,
  });

  factory MeEmployeeContextResponse.fromJson(Map<String, dynamic> json) {
    final positionJson = json['position'] as Map<String, dynamic>?;
    final unitJson = json['unit'] as Map<String, dynamic>?;
    return MeEmployeeContextResponse(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      documentNumber: json['document_number'] as String?,
      position: positionJson == null
          ? null
          : MeInstitutionalPositionResponse.fromJson(positionJson),
      unit: unitJson == null
          ? null
          : MeInstitutionalUnitResponse.fromJson(unitJson),
    );
  }

  final String id;
  final String fullName;
  final String? documentNumber;
  final MeInstitutionalPositionResponse? position;
  final MeInstitutionalUnitResponse? unit;
}
