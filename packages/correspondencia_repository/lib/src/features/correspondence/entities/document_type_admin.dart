import 'package:equatable/equatable.dart';
import 'package:correspondencia_api/correspondencia_api.dart'
    show DocumentBehavior;

class DocumentTypeAdmin extends Equatable {
  const DocumentTypeAdmin({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    this.profile = 'GENERIC',
    this.behaviorLocked = true,
    DocumentBehavior? behavior,
    this.isOperational = false,
    this.creationPermission,
    this.minimumHierarchyId,
    this.minimumHierarchyName,
    required this.createdAt,
    required this.updatedAt,
  }) : _behavior = behavior;

  final String id;
  final String code;
  final String name;
  final bool isActive;
  final String profile;
  final bool behaviorLocked;
  final DocumentBehavior? _behavior;
  DocumentBehavior get behavior =>
      _behavior ?? DocumentBehavior.fromLegacy(code, profile);
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
        behaviorLocked,
        behavior,
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
    this.behavior = DocumentBehavior.generic,
  });

  final String code;
  final String name;
  final DocumentBehavior behavior;

  @override
  List<Object?> get props => [code, name, behavior];
}

class DocumentTypeUpdateInput extends Equatable {
  const DocumentTypeUpdateInput({required this.name, this.behavior});

  final String name;
  final DocumentBehavior? behavior;

  @override
  List<Object?> get props => [name, behavior];
}
