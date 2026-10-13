import 'package:equatable/equatable.dart';

class AuthorityEmployee extends Equatable {
  const AuthorityEmployee(
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
  @override
  List<Object?> get props =>
      [employeeId, employeeName, positionName, unitName, documentNumber];
}

class InstitutionalSettings extends Equatable {
  const InstitutionalSettings(
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
  final List<AuthorityEmployee> initialRecipients;
  final String? mayorEmployeeId;
  final AuthorityEmployee? mayor;
  final String? mayorValidationError;
  @override
  List<Object?> get props =>
      [mayorDisplayName, mayorEmployeeId, mayor, mayorValidationError,
       intakeUnitId, intakeUnitName, initialRecipientEmployeeIds, initialRecipients];
}
