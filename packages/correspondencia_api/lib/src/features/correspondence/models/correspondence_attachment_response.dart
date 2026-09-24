class CorrespondenceAttachmentResponse {
  const CorrespondenceAttachmentResponse({
    required this.id,
    required this.correspondenceId,
    this.originalFilename,
    this.mimeType,
    this.sizeBytes,
    this.sha256,
    required this.isActive,
    required this.createdByUserId,
    this.createdByUsername,
    required this.createdAt,
    this.deletedAt,
  });

  factory CorrespondenceAttachmentResponse.fromJson(Map<String, dynamic> json) {
    return CorrespondenceAttachmentResponse(
      id: json['id'] as String,
      correspondenceId: json['correspondence_id'] as String,
      originalFilename: json['original_filename'] as String?,
      mimeType: json['mime_type'] as String?,
      sizeBytes: json['size_bytes'] as int?,
      sha256: json['sha256'] as String?,
      isActive: json['is_active'] as bool,
      createdByUserId: json['created_by_user_id'] as String,
      createdByUsername: json['created_by_username'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
    );
  }

  final String id;
  final String correspondenceId;
  final String? originalFilename;
  final String? mimeType;
  final int? sizeBytes;
  final String? sha256;
  final bool isActive;
  final String createdByUserId;
  final String? createdByUsername;
  final DateTime createdAt;
  final DateTime? deletedAt;
}
