class PositionAdminResponse {
  const PositionAdminResponse({
    required this.id,
    this.hierarchyCode,
    this.hierarchyName,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.description,
    this.canViewUnitCorrespondence = false,
    this.hierarchyId,
    this.createdByUserId,
    this.updatedByUserId,
  });

  factory PositionAdminResponse.fromJson(Map<String, dynamic> json) {
    return PositionAdminResponse(
      id: json['id'] as String,
      hierarchyId: json['hierarchy_id'] as String?,
      hierarchyCode: json['hierarchy_code'] as String?,
      hierarchyName: json['hierarchy_name'] as String?,
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
  final String? hierarchyCode;
  final String? hierarchyName;
  final String? code;
  final String name;
  final String? description;
  final bool canViewUnitCorrespondence;
  final String? hierarchyId;
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
    this.hierarchyId,
  });

  final String code;
  final String name;
  final String? description;
  final bool canViewUnitCorrespondence;
  final String? hierarchyId;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'can_view_unit_correspondence': canViewUnitCorrespondence,
        'hierarchy_id': hierarchyId,
        if (description != null) 'description': description,
      };
}

class UpdatePositionRequest {
  const UpdatePositionRequest({
    required this.code,
    required this.name,
    this.description,
    this.canViewUnitCorrespondence = false,
    this.hierarchyId,
  });

  final String code;
  final String name;
  final String? description;
  final bool canViewUnitCorrespondence;
  final String? hierarchyId;

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'can_view_unit_correspondence': canViewUnitCorrespondence,
        'hierarchy_id': hierarchyId,
        if (description != null) 'description': description,
      };
}

class PositionHierarchyResponse {
  const PositionHierarchyResponse(
      {required this.id,
      required this.code,
      required this.name,
      required this.rank,
      required this.isActive});
  final String id;
  final String code;
  final String name;
  final int rank;
  final bool isActive;
  factory PositionHierarchyResponse.fromJson(Map<String, dynamic> json) =>
      PositionHierarchyResponse(
          id: json['id'] as String,
          code: json['code'] as String,
          name: json['name'] as String,
          rank: json['rank'] as int,
          isActive: json['is_active'] as bool? ?? true);
}
