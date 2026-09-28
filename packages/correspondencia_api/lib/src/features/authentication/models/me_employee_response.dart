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

class MeInstitutionalPositionResponse {
  const MeInstitutionalPositionResponse({
    required this.id,
    required this.name,
  });

  factory MeInstitutionalPositionResponse.fromJson(Map<String, dynamic> json) {
    return MeInstitutionalPositionResponse(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;
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
