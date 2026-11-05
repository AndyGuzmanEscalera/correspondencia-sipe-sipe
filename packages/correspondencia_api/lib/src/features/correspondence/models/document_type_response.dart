import 'document_behavior.dart';

class DocumentTypeResponse {
  const DocumentTypeResponse({
    required this.id,
    required this.code,
    required this.name,
    this.profile = 'GENERIC',
    DocumentBehavior? behavior,
    this.isOperational = false,
    this.creationPermission,
    this.minimumHierarchyId,
  }) : _behavior = behavior;

  factory DocumentTypeResponse.fromJson(Map<String, dynamic> json) {
    return DocumentTypeResponse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      profile: json['profile'] as String? ?? 'GENERIC',
      behavior: json['behavior'] == null
          ? null
          : DocumentBehavior.fromJson(json['behavior'] as String),
      isOperational: json['is_operational'] as bool? ?? false,
      creationPermission: json['creation_permission'] as String?,
      minimumHierarchyId: json['minimum_hierarchy_id'] as String?,
    );
  }

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
}
