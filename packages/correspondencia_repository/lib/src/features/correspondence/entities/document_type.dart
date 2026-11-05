import 'package:equatable/equatable.dart';
import 'package:correspondencia_api/correspondencia_api.dart'
    show DocumentBehavior;

class DocumentType extends Equatable {
  const DocumentType({
    required this.id,
    required this.code,
    required this.name,
    this.profile = 'GENERIC',
    DocumentBehavior? behavior,
    this.isOperational = false,
    this.creationPermission,
    this.minimumHierarchyId,
  }) : _behavior = behavior;

  final String id;
  final String code;
  final String name;
  final String profile;
  final DocumentBehavior? _behavior;
  DocumentBehavior get behavior =>
      _behavior ?? DocumentBehavior.fromLegacy(code, profile);
  final bool isOperational;
  final String? creationPermission;
  final String? minimumHierarchyId;

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        profile,
        behavior,
        isOperational,
        creationPermission,
        minimumHierarchyId
      ];
}
