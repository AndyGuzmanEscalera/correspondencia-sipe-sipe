import 'package:equatable/equatable.dart';

class InstitutionalMayor extends Equatable {
  const InstitutionalMayor({
    required this.userId,
    required this.employeeId,
    required this.unitId,
    required this.employeeName,
    required this.positionName,
    required this.unitName,
    required this.paraLabel,
  });

  final String userId;
  final String employeeId;
  final String unitId;
  final String employeeName;
  final String positionName;
  final String unitName;
  final String paraLabel;

  @override
  List<Object?> get props => [
        userId,
        employeeId,
        unitId,
        employeeName,
        positionName,
        unitName,
        paraLabel,
      ];
}
