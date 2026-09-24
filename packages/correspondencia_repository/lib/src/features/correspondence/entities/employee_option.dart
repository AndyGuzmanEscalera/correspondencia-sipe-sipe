import 'package:equatable/equatable.dart';

class EmployeeOption extends Equatable {
  const EmployeeOption({
    required this.id,
    required this.fullName,
    this.unitId,
    this.unitName,
    this.positionName,
    this.documentNumber,
  });

  final String id;
  final String fullName;
  final String? unitId;
  final String? unitName;
  final String? positionName;
  final String? documentNumber;

  @override
  List<Object?> get props => [
        id,
        fullName,
        unitId,
        unitName,
        positionName,
        documentNumber,
      ];
}
