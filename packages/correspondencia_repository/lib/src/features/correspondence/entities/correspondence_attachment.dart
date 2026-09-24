import 'package:equatable/equatable.dart';

class CorrespondenceAttachment extends Equatable {
  const CorrespondenceAttachment({
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

  @override
  List<Object?> get props => [
        id,
        correspondenceId,
        originalFilename,
        mimeType,
        sizeBytes,
        sha256,
        isActive,
        createdByUserId,
        createdByUsername,
        createdAt,
        deletedAt,
      ];
}

class UploadAttachmentInput extends Equatable {
  const UploadAttachmentInput({
    required this.filename,
    required this.bytes,
    this.mimeType,
  });

  final String filename;
  final List<int> bytes;
  final String? mimeType;

  @override
  List<Object?> get props => [filename, bytes, mimeType];
}
