import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_movement_entity.dart';

final externalCorrespondence = CorrespondenceEntity(
  id: 'corr-ext',
  uniqueNumber: 1,
  year: 2026,
  cite: 'CITE-2026-001',
  routeNumber: 'HR-2026-000001',
  type: CorrespondenceTypeCode.ce,
  priority: 'Alta',
  subject: 'Solicitud externa',
  externalSender: 'Ciudadano Test',
  externalRecipient: 'Sistemas',
  currentUserName: 'Usuario Destino',
  registeredAt: DateTime.utc(2026, 1, 15),
  statusLabel: 'Activo',
  documentTypeName: 'Carta',
  reference: 'REF-001',
  originDescription: 'Ventanilla',
  senderDocument: '1234567',
);

final internalCorrespondence = CorrespondenceEntity(
  id: 'corr-int',
  uniqueNumber: 2,
  year: 2026,
  cite: '',
  routeNumber: 'HR-2026-000002',
  type: CorrespondenceTypeCode.ci,
  priority: 'Media',
  subject: 'Memorándum interno',
  externalSender: '',
  externalRecipient: 'Secretaría',
  currentUserName: '',
  registeredAt: DateTime.utc(2026, 1, 16),
  statusLabel: 'Activo',
  documentTypeName: 'Memorándum',
  originUnitName: 'Sistemas',
  originUserName: 'Juan Pérez',
);

final vigenteMovement = CorrespondenceMovementEntity(
  id: 'mov-1',
  sequenceNumber: 1,
  movementType: 'CREATED',
  movementTypeLabel: 'Registro',
  toUnitName: 'Sistemas',
  toUserName: 'Usuario Destino',
  instruction: 'Atender',
  createdByUsername: 'admin',
  createdAt: DateTime.utc(2026, 1, 15, 10),
);

final cancelledMovement = CorrespondenceMovementEntity(
  id: 'mov-2',
  sequenceNumber: 2,
  movementType: 'DERIVED',
  movementTypeLabel: 'Derivación',
  fromUnitName: 'Sistemas',
  toUnitName: 'Secretaría',
  instruction: 'Revisar',
  createdByUsername: 'admin',
  createdAt: DateTime.utc(2026, 1, 16, 11),
  cancelledAt: DateTime.utc(2026, 1, 17),
  cancellationReason: 'Error de destino',
);
