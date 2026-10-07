class InstitutionalMayorResponse {
  const InstitutionalMayorResponse({
    required this.userId,
    required this.employeeId,
    required this.unitId,
    required this.employeeName,
    required this.positionName,
    required this.unitName,
    required this.paraLabel,
  });

  factory InstitutionalMayorResponse.fromJson(Map<String, dynamic> json) {
    return InstitutionalMayorResponse(
      userId: json['user_id'] as String,
      employeeId: json['employee_id'] as String,
      unitId: json['unit_id'] as String,
      employeeName: json['employee_name'] as String,
      positionName: json['position_name'] as String,
      unitName: json['unit_name'] as String,
      paraLabel: json['para_label'] as String,
    );
  }

  final String userId;
  final String employeeId;
  final String unitId;
  final String employeeName;
  final String positionName;
  final String unitName;
  final String paraLabel;
}
