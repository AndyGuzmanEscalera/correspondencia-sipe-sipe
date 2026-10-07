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
      this.mayorEmployeeId,
      this.mayor,
      this.mayorValidationError});
  final String? mayorDisplayName;
  final String? mayorEmployeeId;
  final AuthorityEmployee? mayor;
  final String? mayorValidationError;
  @override
  List<Object?> get props =>
      [mayorDisplayName, mayorEmployeeId, mayor, mayorValidationError];
}
