import 'package:correspondencia_api/correspondencia_api.dart';

import '../entities/correspondence.dart';
import '../entities/correspondence_attachment.dart';
import '../entities/correspondence_movement.dart';
import '../entities/create_correspondence_input.dart';
import '../entities/document_type.dart';
import '../entities/employee_option.dart';
import '../entities/inbox_counts.dart';
import '../entities/sent_count.dart';

extension DocumentTypeResponseMapper on DocumentTypeResponse {
  DocumentType toEntity() => DocumentType(id: id, code: code, name: name);
}

extension EmployeeOptionResponseMapper on EmployeeOptionResponse {
  EmployeeOption toEntity() => EmployeeOption(
        id: id,
        fullName: fullName,
        unitId: unitId,
        unitName: unitName,
        positionName: positionName,
        documentNumber: documentNumber,
      );
}

extension CorrespondenceResponseMapper on CorrespondenceResponse {
  Correspondence toEntity() => Correspondence(
        id: id,
        routeNumber: routeNumber,
        routeYear: routeYear,
        routeSequence: routeSequence,
        documentNumber: documentNumber,
        correspondenceType: correspondenceType,
        documentTypeCode: documentTypeCode,
        documentTypeName: documentTypeName,
        subject: subject,
        priority: priority,
        status: status,
        currentUnitName: currentUnitName,
        currentUserName: currentUserName,
        currentUserIsActive: currentUserIsActive,
        cite: cite,
        registeredAt: registeredAt,
        reference: reference,
        description: description,
        senderName: senderName,
        senderDocument: senderDocument,
        senderContact: senderContact,
        originDescription: originDescription,
        originUnitId: originUnitId,
        originUnitName: originUnitName,
        originUserId: originUserId,
        originUserName: originUserName,
        originEmployeeId: originEmployeeId,
        originEmployeeName: originEmployeeName,
        currentUnitId: currentUnitId,
        currentUserId: currentUserId,
        createdByUsername: createdByUsername,
        lastSentAt: lastSentAt,
      );
}

extension CorrespondenceSentCountResponseMapper
    on CorrespondenceSentCountResponse {
  SentCount toEntity() => SentCount(total: total);
}

extension CorrespondenceListResponseMapper on CorrespondenceListResponse {
  CorrespondencePage toEntity() => CorrespondencePage(
        items: items.map((item) => item.toEntity()).toList(),
        page: page,
        pageSize: pageSize,
        total: total,
        totalPages: totalPages,
      );
}

extension CorrespondenceInboxCountsResponseMapper
    on CorrespondenceInboxCountsResponse {
  InboxCounts toEntity() => InboxCounts(mine: mine, unit: unit);
}

extension CorrespondenceMovementResponseMapper on CorrespondenceMovementResponse {
  CorrespondenceMovement toEntity() => CorrespondenceMovement(
        id: id,
        sequenceNumber: sequenceNumber,
        movementType: movementType,
        fromUnitName: fromUnitName,
        fromUserName: fromUserName,
        toUnitName: toUnitName,
        toUserName: toUserName,
        instruction: instruction,
        observation: observation,
        createdByUsername: createdByUsername,
        createdAt: createdAt,
        cancelledAt: cancelledAt,
        cancellationReason: cancellationReason,
      );
}

extension CorrespondenceAttachmentResponseMapper on CorrespondenceAttachmentResponse {
  CorrespondenceAttachment toEntity() => CorrespondenceAttachment(
        id: id,
        correspondenceId: correspondenceId,
        originalFilename: originalFilename,
        mimeType: mimeType,
        sizeBytes: sizeBytes,
        sha256: sha256,
        isActive: isActive,
        createdByUserId: createdByUserId,
        createdByUsername: createdByUsername,
        createdAt: createdAt,
        deletedAt: deletedAt,
      );
}

extension CreateCorrespondenceInputMapper on CreateCorrespondenceInput {
  CreateCorrespondenceRequest toRequest() => CreateCorrespondenceRequest(
        correspondenceType: correspondenceType,
        documentTypeId: documentTypeId,
        subject: subject,
        priority: priority,
        reference: reference,
        description: description,
        originEmployeeId: originEmployeeId,
        senderName: senderName,
        senderDocument: senderDocument,
        senderContact: senderContact,
        originDescription: originDescription,
        initialToUnitId: initialToUnitId,
        initialToUserId: initialToUserId,
        initialInstruction: initialInstruction,
      );
}

extension DeriveCorrespondenceInputMapper on DeriveCorrespondenceInput {
  DeriveCorrespondenceRequest toRequest() => DeriveCorrespondenceRequest(
        toUnitId: toUnitId,
        toUserId: toUserId,
        instruction: instruction,
        observation: observation,
      );
}

extension CorrespondenceLifecycleInputMapper on CorrespondenceLifecycleInput {
  CorrespondenceLifecycleRequest toRequest() => CorrespondenceLifecycleRequest(
        observation: observation,
      );
}
