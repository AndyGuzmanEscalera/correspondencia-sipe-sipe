class EmployeeAdminResponse {
  const EmployeeAdminResponse({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.documentNumber,
    this.email,
    this.phone,
    this.unitId,
    this.unitName,
    this.positionId,
    this.positionName,
    this.createdByUserId,
    this.updatedByUserId,
  });

  factory EmployeeAdminResponse.fromJson(Map<String, dynamic> json) {
    return EmployeeAdminResponse(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      documentNumber: json['document_number'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      unitId: json['unit_id'] as String?,
      unitName: json['unit_name'] as String?,
      positionId: json['position_id'] as String?,
      positionName: json['position_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdByUserId: json['created_by_user_id'] as String?,
      updatedByUserId: json['updated_by_user_id'] as String?,
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String? documentNumber;
  final String? email;
  final String? phone;
  final String? unitId;
  final String? unitName;
  final String? positionId;
  final String? positionName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdByUserId;
  final String? updatedByUserId;
}

class CreateEmployeeRequest {
  const CreateEmployeeRequest({
    required this.firstName,
    required this.lastName,
    required this.documentNumber,
    required this.unitId,
    required this.positionId,
    this.email,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String documentNumber;
  final String? email;
  final String? phone;
  final String unitId;
  final String positionId;

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'document_number': documentNumber,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'unit_id': unitId,
        'position_id': positionId,
      };
}

class UpdateEmployeeRequest {
  const UpdateEmployeeRequest({
    required this.firstName,
    required this.lastName,
    required this.documentNumber,
    required this.unitId,
    required this.positionId,
    this.email,
    this.phone,
  });

  final String firstName;
  final String lastName;
  final String documentNumber;
  final String? email;
  final String? phone;
  final String unitId;
  final String positionId;

  Map<String, dynamic> toJson() => {
        'first_name': firstName,
        'last_name': lastName,
        'document_number': documentNumber,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'unit_id': unitId,
        'position_id': positionId,
      };
}
