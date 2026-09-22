import 'package:correspondencia_api/correspondencia_api.dart';

import '../entities/correspondence.dart';
import '../entities/correspondence_movement.dart';
import '../entities/create_correspondence_input.dart';
import '../entities/document_type.dart';

extension DocumentTypeResponseMapper on DocumentTypeResponse {
  DocumentType toEntity() => DocumentType(id: id, code: code, name: name);
}

extension CorrespondenceResponseMapper on CorrespondenceResponse {
  Correspondence toEntity() => Correspondence(
        id: id,
        routeNumber: routeNumber,
        routeYear: routeYear,
        routeSequence: routeSequence,
        correspondenceType: correspondenceType,
        documentTypeCode: documentTypeCode,
        documentTypeName: documentTypeName,
        subject: subject,
        priority: priority,
        status: status,
        currentUnitName: currentUnitName,
        currentUserName: currentUserName,
        cite: cite,
        registeredAt: registeredAt,
        reference: reference,
        senderName: senderName,
        senderDocument: senderDocument,
        senderContact: senderContact,
        originDescription: originDescription,
        originUnitId: originUnitId,
        originUnitName: originUnitName,
        originUserId: originUserId,
        originUserName: originUserName,
        currentUnitId: currentUnitId,
        currentUserId: currentUserId,
        createdByUsername: createdByUsername,
      );
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

extension CreateCorrespondenceInputMapper on CreateCorrespondenceInput {
  CreateCorrespondenceRequest toRequest() => CreateCorrespondenceRequest(
        correspondenceType: correspondenceType,
        documentTypeId: documentTypeId,
        subject: subject,
        priority: priority,
        reference: reference,
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
