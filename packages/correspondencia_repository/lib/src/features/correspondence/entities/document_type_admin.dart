import 'package:equatable/equatable.dart';

class DocumentTypeAdmin extends Equatable {
  const DocumentTypeAdmin({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    this.profile = 'GENERIC',
    this.isOperational = false,
    this.creationPermission,
    this.minimumHierarchyId,
    this.minimumHierarchyName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final bool isActive;
  final String profile;
  final bool isOperational;
  final String? creationPermission;
  final String? minimumHierarchyId;
  final String? minimumHierarchyName;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        isActive,
        createdAt,
        updatedAt,
        profile,
        isOperational,
        creationPermission,
        minimumHierarchyId,
        minimumHierarchyName
      ];
}

class DocumentTypeInput extends Equatable {
  const DocumentTypeInput({
    required this.code,
    required this.name,
  });

  final String code;
  final String name;

  @override
  List<Object?> get props => [code, name];
}

class DocumentTypeUpdateInput extends Equatable {
  const DocumentTypeUpdateInput({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}
