class EmployeeOptionResponse {
  const EmployeeOptionResponse({
    required this.id,
    required this.fullName,
    this.unitId,
    this.unitName,
    this.positionName,
    this.documentNumber,
  });

  factory EmployeeOptionResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeOptionResponse(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      unitId: json['unit_id'] as String?,
      unitName: json['unit_name'] as String?,
      positionName: json['position_name'] as String?,
      documentNumber: json['document_number'] as String?,
    );
  }

  final String id;
  final String fullName;
  final String? unitId;
  final String? unitName;
  final String? positionName;
  final String? documentNumber;
}
