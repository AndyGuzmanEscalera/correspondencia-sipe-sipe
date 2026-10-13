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
      this.intakeUnitId,
      this.intakeUnitName,
      this.initialRecipientEmployeeIds = const [],
      this.initialRecipients = const [],
      this.mayorEmployeeId,
      this.mayor,
      this.mayorValidationError});
  final String? mayorDisplayName;
  final String? intakeUnitId;
  final String? intakeUnitName;
  final List<String> initialRecipientEmployeeIds;
  final List<AuthorityEmployeeResponse> initialRecipients;
  final String? mayorEmployeeId;
  final AuthorityEmployeeResponse? mayor;
  final String? mayorValidationError;
  factory InstitutionalSettingsResponse.fromJson(Map<String, dynamic> json) =>
      InstitutionalSettingsResponse(
          intakeUnitId: json['intake_unit_id'] as String?,
          intakeUnitName: json['intake_unit_name'] as String?,
          initialRecipientEmployeeIds: List<String>.from(json['initial_recipient_employee_ids'] as List? ?? []),
          initialRecipients: (json['initial_recipients'] as List? ?? []).map((x) => AuthorityEmployeeResponse.fromJson(x as Map<String, dynamic>)).toList(),
          mayorDisplayName: json['mayor_display_name'] as String?,
          mayorEmployeeId: json['mayor_employee_id'] as String?,
          mayor: json['mayor'] == null
              ? null
              : AuthorityEmployeeResponse.fromJson(
                  json['mayor'] as Map<String, dynamic>),
          mayorValidationError: json['mayor_validation_error'] as String?);
  Map<String, dynamic> toJson() => {
        'mayor_display_name': mayorDisplayName,
        'intake_unit_id': intakeUnitId,
        'intake_unit_name': intakeUnitName,
        'initial_recipient_employee_ids': initialRecipientEmployeeIds,
        'initial_recipients': initialRecipients.map((x) => x.toJson()).toList(),
        'mayor_employee_id': mayorEmployeeId,
        'mayor': mayor?.toJson(),
        'mayor_validation_error': mayorValidationError
      };
}
