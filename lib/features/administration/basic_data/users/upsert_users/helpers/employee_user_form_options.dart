import 'package:correspondencia_repository/correspondencia_repository.dart';
import 'package:correspondencia_sipe_sipe/core/util/form/models/form_option.dart';

String? employeeSubtitle(EmployeeAdmin employee) {
  final parts = <String>[
    if (employee.positionName != null && employee.positionName!.trim().isNotEmpty)
      employee.positionName!.trim(),
    if (employee.unitName != null && employee.unitName!.trim().isNotEmpty)
      employee.unitName!.trim(),
  ];
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

List<String> employeeSearchKeywords(EmployeeAdmin employee) {
  return [
    if (employee.documentNumber != null &&
        employee.documentNumber!.trim().isNotEmpty)
      employee.documentNumber!.trim(),
    if (employee.positionName != null &&
        employee.positionName!.trim().isNotEmpty)
      employee.positionName!.trim(),
    if (employee.unitName != null && employee.unitName!.trim().isNotEmpty)
      employee.unitName!.trim(),
  ];
}

FormOption<String> employeeToFormOption(EmployeeAdmin employee) {
  return FormOption<String>(
    id: employee.id.hashCode,
    text: employee.fullName,
    value: employee.id,
    description: employeeSubtitle(employee),
    keywords: employeeSearchKeywords(employee),
  );
}
