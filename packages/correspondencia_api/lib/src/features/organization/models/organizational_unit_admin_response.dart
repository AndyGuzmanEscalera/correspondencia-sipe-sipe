class OrganizationalUnitAdminResponse {
  const OrganizationalUnitAdminResponse({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.description,
    this.parentId,
    this.parentName,
    this.createdByUserId,
    this.updatedByUserId,
  });

  factory OrganizationalUnitAdminResponse.fromJson(Map<String, dynamic> json) {
    return OrganizationalUnitAdminResponse(
      id: json['id'] as String,
      code: json['code'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parent_id'] as String?,
      parentName: json['parent_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdByUserId: json['created_by_user_id'] as String?,
      updatedByUserId: json['updated_by_user_id'] as String?,
    );
  }

  final String id;
  final String? code;
  final String name;
  final String? description;
  final String? parentId;
  final String? parentName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByUserId;
  final String? updatedByUserId;
}

class CreateOrganizationalUnitRequest {
  const CreateOrganizationalUnitRequest({
    required this.code,
    required this.name,
    this.description,
    this.parentId,
  });

  final String code;
  final String name;
  final String? description;
  final String? parentId;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        if (description != null) 'description': description,
        if (parentId != null) 'parent_id': parentId,
      };
}

class UpdateOrganizationalUnitRequest {
  const UpdateOrganizationalUnitRequest({
    required this.code,
    required this.name,
    this.description,
    this.parentId,
  });

  final String code;
  final String name;
  final String? description;
  final String? parentId;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        if (description != null) 'description': description,
        if (parentId != null) 'parent_id': parentId,
      };
}
