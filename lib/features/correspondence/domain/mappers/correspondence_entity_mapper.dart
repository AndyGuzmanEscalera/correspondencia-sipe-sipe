import 'package:correspondencia_repository/correspondencia_repository.dart'
    as repo;
import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';

extension CorrespondenceToEntity on repo.Correspondence {
  CorrespondenceEntity toUiEntity() => CorrespondenceEntity(
        id: id,
        uniqueNumber: routeSequence,
        year: routeYear,
        cite: displayCite,
        routeNumber: routeNumber,
        type: correspondenceType == 'INTERNAL'
            ? CorrespondenceTypeCode.ci
            : CorrespondenceTypeCode.ce,
        priority: _priorityLabel(priority),
        subject: subject,
        externalSender: senderName ?? originUserName ?? '',
        externalRecipient: currentUnitName ?? '',
        currentUserName: currentUserName ?? '',
        registeredAt: registeredAt,
        statusLabel: _statusLabel(status),
        documentTypeName: documentTypeName,
        reference: reference,
        originDescription: originDescription,
        originUnitName: originUnitName,
        originUserName: originUserName,
        senderDocument: senderDocument,
        senderContact: senderContact,
      );
}

extension CorrespondenceMovementToEntity on repo.CorrespondenceMovement {
  CorrespondenceMovementEntity toUiEntity() => CorrespondenceMovementEntity(
        id: id,
        sequenceNumber: sequenceNumber,
        movementType: movementType,
        movementTypeLabel: _movementLabel(movementType),
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

String _priorityLabel(String code) => switch (code) {
      'HIGH' => 'Alta',
      'MEDIUM' => 'Media',
      'LOW' => 'Baja',
      _ => code,
    };

String _statusLabel(String code) => switch (code) {
      'ACTIVE' => 'Activo',
      'CONCLUDED' => 'Concluido',
      _ => code,
    };

String _movementLabel(String code) => switch (code) {
      'CREATED' => 'Registro',
      'DERIVED' => 'Derivación',
      _ => code,
    };

String priorityCodeFromLabel(String label) => switch (label) {
      'Alta' => 'HIGH',
      'Media' => 'MEDIUM',
      'Baja' => 'LOW',
      _ => label,
    };

String correspondenceTypeCodeFromUi(CorrespondenceTypeCode type) =>
    type == CorrespondenceTypeCode.ci ? 'INTERNAL' : 'EXTERNAL';
