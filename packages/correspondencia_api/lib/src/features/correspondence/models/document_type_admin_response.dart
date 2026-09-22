class DocumentTypeAdminResponse {
  const DocumentTypeAdminResponse({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdByUserId,
    this.updatedByUserId,
  });

  factory DocumentTypeAdminResponse.fromJson(Map<String, dynamic> json) {
    return DocumentTypeAdminResponse(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
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
  });

  final String code;
  final String name;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
      };
}

class UpdateDocumentTypeRequest {
  const UpdateDocumentTypeRequest({required this.name});

  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}
