class CorrespondenceResponse {
  const CorrespondenceResponse({
    required this.id,
    required this.routeNumber,
    required this.routeYear,
    required this.routeSequence,
    required this.correspondenceType,
    required this.documentTypeCode,
    required this.documentTypeName,
    required this.subject,
    required this.priority,
    required this.status,
    this.currentUnitName,
    this.currentUserName,
    this.cite,
    required this.registeredAt,
    this.reference,
    this.senderName,
    this.senderDocument,
    this.senderContact,
    this.originDescription,
    this.originUnitId,
    this.originUnitName,
    this.originUserId,
    this.originUserName,
    this.currentUnitId,
    this.currentUserId,
    this.citeSequence,
    this.citeYear,
    this.concludedAt,
    this.reopenedAt,
    this.createdByUserId,
    this.createdByUsername,
  });

  factory CorrespondenceResponse.fromJson(Map<String, dynamic> json) {
    return CorrespondenceResponse(
      id: json['id'] as String,
      routeNumber: json['route_number'] as String,
      routeYear: json['route_year'] as int,
      routeSequence: json['route_sequence'] as int,
      correspondenceType: json['correspondence_type'] as String,
      documentTypeCode: json['document_type_code'] as String,
      documentTypeName: json['document_type_name'] as String,
      subject: json['subject'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      currentUnitName: json['current_unit_name'] as String?,
      currentUserName: json['current_user_name'] as String?,
      cite: json['cite'] as String?,
      registeredAt: DateTime.parse(json['registered_at'] as String),
      reference: json['reference'] as String?,
      senderName: json['sender_name'] as String?,
      senderDocument: json['sender_document'] as String?,
      senderContact: json['sender_contact'] as String?,
      originDescription: json['origin_description'] as String?,
      originUnitId: json['origin_unit_id'] as String?,
      originUnitName: json['origin_unit_name'] as String?,
      originUserId: json['origin_user_id'] as String?,
      originUserName: json['origin_user_name'] as String?,
      currentUnitId: json['current_unit_id'] as String?,
      currentUserId: json['current_user_id'] as String?,
      citeSequence: json['cite_sequence'] as int?,
      citeYear: json['cite_year'] as int?,
      concludedAt: json['concluded_at'] != null
          ? DateTime.parse(json['concluded_at'] as String)
          : null,
      reopenedAt: json['reopened_at'] != null
          ? DateTime.parse(json['reopened_at'] as String)
          : null,
      createdByUserId: json['created_by_user_id'] as String?,
      createdByUsername: json['created_by_username'] as String?,
    );
  }

  final String id;
  final String routeNumber;
  final int routeYear;
  final int routeSequence;
  final String correspondenceType;
  final String documentTypeCode;
  final String documentTypeName;
  final String subject;
  final String priority;
  final String status;
  final String? currentUnitName;
  final String? currentUserName;
  final String? cite;
  final DateTime registeredAt;
  final String? reference;
  final String? senderName;
  final String? senderDocument;
  final String? senderContact;
  final String? originDescription;
  final String? originUnitId;
  final String? originUnitName;
  final String? originUserId;
  final String? originUserName;
  final String? currentUnitId;
  final String? currentUserId;
  final int? citeSequence;
  final int? citeYear;
  final DateTime? concludedAt;
  final DateTime? reopenedAt;
  final String? createdByUserId;
  final String? createdByUsername;
}
