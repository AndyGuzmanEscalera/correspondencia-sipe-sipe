import 'document_behavior.dart';

class DocumentTypeAdminResponse {
  const DocumentTypeAdminResponse({
    required this.id,
    required this.code,
    required this.name,
    this.profile = 'GENERIC',
    this.behaviorLocked = true,
    DocumentBehavior? behavior,
    this.isOperational = false,
    this.creationPermission,
    this.minimumHierarchyId,
    this.minimumHierarchyName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdByUserId,
    this.updatedByUserId,
  }) : _behavior = behavior;

  factory DocumentTypeAdminResponse.fromJson(Map<String, dynamic> json) {
    return DocumentTypeAdminResponse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      profile: json['profile'] as String? ?? 'GENERIC',
      behaviorLocked: json['behavior_locked'] as bool? ?? true,
      behavior: json['behavior'] == null
          ? null
          : DocumentBehavior.fromJson(json['behavior'] as String),
      isOperational: json['is_operational'] as bool? ?? false,
      creationPermission: json['creation_permission'] as String?,
      minimumHierarchyId: json['minimum_hierarchy_id'] as String?,
      minimumHierarchyName: json['minimum_hierarchy_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdByUserId: json['created_by_user_id'] as String?,
      updatedByUserId: json['updated_by_user_id'] as String?,
    );
  }

  final String id;
  final String code;
  final String name;
  final String profile;
  final bool behaviorLocked;
  final DocumentBehavior? _behavior;
  DocumentBehavior get behavior =>
      _behavior ?? DocumentBehavior.fromLegacy(code, profile);
  final bool isOperational;
  final String? creationPermission;
  final String? minimumHierarchyId;
  final String? minimumHierarchyName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByUserId;
  final String? updatedByUserId;
}

class CreateDocumentTypeRequest {
  const CreateDocumentTypeRequest({
    required this.code,
    required this.name,
    this.behavior = DocumentBehavior.generic,
  });

  final String code;
  final String name;
  final DocumentBehavior behavior;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'behavior': behavior.value,
      };
}

class UpdateDocumentTypeRequest {
  const UpdateDocumentTypeRequest({required this.name, this.behavior});

  final String name;
  final DocumentBehavior? behavior;

  Map<String, dynamic> toJson() =>
      {'name': name, if (behavior != null) 'behavior': behavior!.value};
}
