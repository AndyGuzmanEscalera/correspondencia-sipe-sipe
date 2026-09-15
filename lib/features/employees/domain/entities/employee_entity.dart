import 'package:equatable/equatable.dart';

class EmployeeEntity extends Equatable {
  const EmployeeEntity({
    required this.id,
    required this.fullName,
    required this.positionName,
    required this.unitName,
    required this.documentId,
    required this.isActive,
  });

  final String id;
  final String fullName;
  final String positionName;
  final String unitName;
  final String documentId;
  final bool isActive;

  @override
  List<Object?> get props =>
      [id, fullName, positionName, unitName, documentId, isActive];
}
