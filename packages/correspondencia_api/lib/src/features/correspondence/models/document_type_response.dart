class DocumentTypeResponse {
  const DocumentTypeResponse({
    required this.id,
    required this.code,
    required this.name,
    this.profile = 'GENERIC',
    this.isOperational = false,
    this.creationPermission,
    this.minimumHierarchyId,
  });

  factory DocumentTypeResponse.fromJson(Map<String, dynamic> json) {
    return DocumentTypeResponse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      profile: json['profile'] as String? ?? 'GENERIC',
      isOperational: json['is_operational'] as bool? ?? false,
      creationPermission: json['creation_permission'] as String?,
      minimumHierarchyId: json['minimum_hierarchy_id'] as String?,
    );
  }

  final String id;
  final String code;
  final String name;
  final String profile;
  final bool isOperational;
  final String? creationPermission;
  final String? minimumHierarchyId;
}
