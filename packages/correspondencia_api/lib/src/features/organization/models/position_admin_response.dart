class PositionAdminResponse {
  const PositionAdminResponse({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.description,
    this.canViewUnitCorrespondence = false,
    this.createdByUserId,
    this.updatedByUserId,
  });

  factory PositionAdminResponse.fromJson(Map<String, dynamic> json) {
    return PositionAdminResponse(
      id: json['id'] as String,
      code: json['code'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      canViewUnitCorrespondence:
          json['can_view_unit_correspondence'] as bool? ?? false,
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
  final bool canViewUnitCorrespondence;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByUserId;
  final String? updatedByUserId;
}

class CreatePositionRequest {
  const CreatePositionRequest({
    required this.code,
    required this.name,
    this.description,
    this.canViewUnitCorrespondence = false,
  });

  final String code;
  final String name;
  final String? description;
  final bool canViewUnitCorrespondence;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'can_view_unit_correspondence': canViewUnitCorrespondence,
        if (description != null) 'description': description,
      };
}

class UpdatePositionRequest {
  const UpdatePositionRequest({
    required this.code,
    required this.name,
    this.description,
    this.canViewUnitCorrespondence = false,
  });

  final String code;
  final String name;
  final String? description;
  final bool canViewUnitCorrespondence;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'can_view_unit_correspondence': canViewUnitCorrespondence,
        if (description != null) 'description': description,
      };
}
