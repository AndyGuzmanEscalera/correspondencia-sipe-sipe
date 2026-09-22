import 'package:equatable/equatable.dart';

class OrganizationalUnitAdmin extends Equatable {
  const OrganizationalUnitAdmin({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.description,
    this.parentId,
    this.parentName,
  });

  final String id;
  final String? code;
  final String name;
  final String? description;
  final String? parentId;
  final String? parentName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        description,
        parentId,
        parentName,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class OrganizationalUnitInput extends Equatable {
  const OrganizationalUnitInput({
    required this.code,
    required this.name,
    this.description,
    this.parentId,
  });

  final String code;
  final String name;
  final String? description;
  final String? parentId;

  @override
  List<Object?> get props => [code, name, description, parentId];
}
