class AuthorityEmployeeResponse {
  const AuthorityEmployeeResponse(
      {required this.employeeId,
      required this.employeeName,
      required this.positionName,
      required this.unitName,
      this.documentNumber});
  final String employeeId;
  final String employeeName;
  final String positionName;
  final String unitName;
  final String? documentNumber;
  factory AuthorityEmployeeResponse.fromJson(Map<String, dynamic> json) =>
      AuthorityEmployeeResponse(
          employeeId: json['employee_id'] as String,
          employeeName: json['employee_name'] as String,
          positionName: json['position_name'] as String,
          unitName: json['unit_name'] as String,
          documentNumber: json['document_number'] as String?);
  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'position_name': positionName,
        'unit_name': unitName,
        'document_number': documentNumber
      };
}

class InstitutionalSettingsResponse {
  const InstitutionalSettingsResponse(
      {this.mayorDisplayName,
      this.mayorEmployeeId,
      this.mayor,
      this.mayorValidationError});
  final String? mayorDisplayName;
  final String? mayorEmployeeId;
  final AuthorityEmployeeResponse? mayor;
  final String? mayorValidationError;
  factory InstitutionalSettingsResponse.fromJson(Map<String, dynamic> json) =>
      InstitutionalSettingsResponse(
          mayorDisplayName: json['mayor_display_name'] as String?,
          mayorEmployeeId: json['mayor_employee_id'] as String?,
          mayor: json['mayor'] == null
              ? null
              : AuthorityEmployeeResponse.fromJson(
                  json['mayor'] as Map<String, dynamic>),
          mayorValidationError: json['mayor_validation_error'] as String?);
  Map<String, dynamic> toJson() => {
        'mayor_display_name': mayorDisplayName,
        'mayor_employee_id': mayorEmployeeId,
        'mayor': mayor?.toJson(),
        'mayor_validation_error': mayorValidationError
      };
}
