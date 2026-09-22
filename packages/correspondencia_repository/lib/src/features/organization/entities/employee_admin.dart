import 'package:equatable/equatable.dart';

class EmployeeAdmin extends Equatable {
  const EmployeeAdmin({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.documentNumber,
    this.email,
    this.phone,
    this.unitId,
    this.unitName,
    this.positionId,
    this.positionName,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? documentNumber;
  final String? email;
  final String? phone;
  final String? unitId;
  final String? unitName;
  final String? positionId;
  final String? positionName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        documentNumber,
        email,
        phone,
        unitId,
        unitName,
        positionId,
        positionName,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class EmployeeInput extends Equatable {
  const EmployeeInput({
    required this.firstName,
    required this.lastName,
    required this.documentNumber,
    required this.unitId,
    required this.positionId,
    this.email,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String documentNumber;
  final String? email;
  final String? phone;
  final String unitId;
  final String positionId;

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        documentNumber,
        email,
        phone,
        unitId,
        positionId,
      ];
}
