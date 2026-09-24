import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/correspondence_entity.dart';
import 'package:correspondencia_sipe_sipe/features/correspondence/domain/entities/derivation_entity.dart';
import 'package:correspondencia_sipe_sipe/features/employees/domain/entities/employee_entity.dart';
import 'package:correspondencia_sipe_sipe/features/units/domain/entities/unit_entity.dart';

class PublicConsultRequest {
  const PublicConsultRequest({
    required this.year,
    required this.fullName,
    required this.documentId,
    required this.phone,
    required this.uniqueNumber,
  });

  final int year;
  final String fullName;
  final String documentId;
  final String phone;
  final int uniqueNumber;
}

class CreateCorrespondenceRequest {
  const CreateCorrespondenceRequest({
    required this.subject,
    required this.type,
    required this.priority,
    required this.externalSender,
    required this.externalRecipient,
    required this.citizenName,
    required this.citizenDocumentId,
    required this.citizenPhone,
  });

  final String subject;
  final CorrespondenceTypeCode type;
  final String priority;
  final String externalSender;
  final String externalRecipient;
  final String citizenName;
  final String citizenDocumentId;
  final String citizenPhone;
}

class LocalStore {
  LocalStore._();

  static final LocalStore instance = LocalStore._();

  final List<CorrespondenceEntity> correspondences = [];
  final List<DerivationEntity> derivations = [];
  final List<EmployeeEntity> employees = [];
  final List<UnitEntity> units = [];

  int _sequence = 100;
  int _nextUniqueNumber = 2;

  void seed() {
    if (correspondences.isNotEmpty) return;

    units.addAll(const [
      UnitEntity(id: 'u1', code: 'RECEPCION', name: 'Recepción', isActive: true),
      UnitEntity(id: 'u2', code: 'SECRETARIA', name: 'Secretaría Municipal', isActive: true),
      UnitEntity(id: 'u3', code: 'JURIDICA', name: 'Unidad Jurídica', isActive: true),
      UnitEntity(id: 'u4', code: 'FINANZAS', name: 'Unidad de Finanzas', isActive: true),
      UnitEntity(id: 'u5', code: 'SISTEMAS', name: 'Unidad de Sistemas', isActive: true),
      UnitEntity(id: 'u6', code: 'URBANISMO', name: 'Unidad de Urbanismo', isActive: true),
    ]);

    employees.addAll(const [
      EmployeeEntity(
        id: 'e1',
        fullName: 'Lic. JAIME MONTERO LOPEZ',
        positionName: 'Técnico SIS I',
        unitName: 'Unidad de Sistemas',
        documentId: '4567890',
        isActive: true,
      ),
      EmployeeEntity(
        id: 'e2',
        fullName: 'Tec. MERLINA LOPEZ MONTIVEROS',
        positionName: 'Responsable de Informática de Sistemas',
        unitName: 'Unidad de Sistemas',
        documentId: '5678901',
        isActive: true,
      ),
      EmployeeEntity(
        id: 'e3',
        fullName: 'Lic. ANA LUCÍA FLORES ROJAS',
        positionName: 'Secretaria Municipal',
        unitName: 'Secretaría Municipal',
        documentId: '6789012',
        isActive: true,
      ),
      EmployeeEntity(
        id: 'e4',
        fullName: 'Sr. GEORGE DOMINGUEZ ROLDAN',
        positionName: 'Ciudadano',
        unitName: 'Externo',
        documentId: '7890123',
        isActive: true,
      ),
    ]);

    final correspondenceOne = CorrespondenceEntity(
      id: 'c1',
      uniqueNumber: 1,
      year: 2026,
      cite: 'GAMSS/REC/SECRE/CE/1/2026',
      routeNumber: 'HR-2026-000001',
      type: CorrespondenceTypeCode.ce,
      priority: 'Baja',
      subject: 'Solicitud de corrección de impuesto',
      externalSender: 'Sr. GEORGE DOMINGUEZ ROLDAN',
      externalRecipient: 'Lic. JAIME MONTERO LOPEZ - Técnico SIS I',
      currentUserName: 'Lic. JAIME MONTERO LOPEZ',
      registeredAt: DateTime(2026, 5, 15),
      statusLabel: 'Recibida',
      documentTypeCode: 'CARTA',
      documentTypeName: 'Carta',
      senderDocument: '7890123',
      senderContact: '70012345',
    );

    correspondences.add(correspondenceOne);

    derivations.addAll([
      DerivationEntity(
        id: 'd1',
        correspondenceId: 'c1',
        sequenceNumber: 1,
        senderName: 'Tec. MERLINA LOPEZ MONTIVEROS',
        recipientName: 'Lic. JAIME MONTERO LOPEZ',
        originUnitName: 'Unidad de Sistemas',
        destinationUnitName: 'Unidad de Sistemas',
        instruction: 'Para corregir',
        statusLabel: 'Recibida',
        sentAt: DateTime(2026, 5, 15, 9, 30),
        receivedAt: DateTime(2026, 5, 15, 10, 15),
        inboxType: InboxType.received,
      ),
      DerivationEntity(
        id: 'd2',
        correspondenceId: 'c2',
        sequenceNumber: 1,
        senderName: 'Lic. ANA LUCÍA FLORES ROJAS',
        recipientName: 'Lic. JAIME MONTERO LOPEZ',
        originUnitName: 'Secretaría Municipal',
        destinationUnitName: 'Unidad de Sistemas',
        instruction: 'Para atención',
        statusLabel: 'Enviada',
        sentAt: DateTime(2026, 5, 10, 8, 0),
        inboxType: InboxType.sent,
      ),
      DerivationEntity(
        id: 'd3',
        correspondenceId: 'c3',
        sequenceNumber: 1,
        senderName: 'Recepción',
        recipientName: 'Lic. ANA LUCÍA FLORES ROJAS',
        originUnitName: 'Recepción',
        destinationUnitName: 'Secretaría Municipal',
        instruction: 'Para su conocimiento',
        statusLabel: 'Pendiente',
        sentAt: DateTime(2026, 5, 14, 11, 0),
        inboxType: InboxType.inbox,
      ),
    ]);

    correspondences.addAll([
      CorrespondenceEntity(
        id: 'c2',
        uniqueNumber: 2,
        year: 2026,
        cite: 'GAMSS/REC/SECRE/CI/2/2026',
        routeNumber: 'HR-2026-000002',
        type: CorrespondenceTypeCode.ci,
        priority: 'Media',
        subject: 'Informe de avance de sistemas',
        externalSender: 'Secretaría Municipal',
        externalRecipient: 'Unidad de Sistemas',
        currentUserName: 'Lic. ANA LUCÍA FLORES ROJAS',
        registeredAt: DateTime(2026, 5, 10),
        statusLabel: 'Enviada',
        documentTypeCode: 'MEMO',
        documentTypeName: 'Memorándum',
        originUnitName: 'Secretaría Municipal',
        originUserName: 'Lic. ANA LUCÍA FLORES ROJAS',
      ),
      CorrespondenceEntity(
        id: 'c3',
        uniqueNumber: 3,
        year: 2026,
        cite: 'GAMSS/REC/SECRE/CE/3/2026',
        routeNumber: 'HR-2026-000003',
        type: CorrespondenceTypeCode.ce,
        priority: 'Alta',
        subject: 'Solicitud de certificación catastral',
        externalSender: 'Ciudadano externo',
        externalRecipient: 'Secretaría Municipal',
        currentUserName: '',
        registeredAt: DateTime(2026, 5, 14),
        statusLabel: 'Pendiente',
        documentTypeCode: 'CARTA',
        documentTypeName: 'Carta',
        senderDocument: '1234567',
        senderContact: '70123456',
      ),
    ]);

    for (var i = 4; i <= 8; i++) {
      correspondences.add(
        CorrespondenceEntity(
          id: 'c$i',
          uniqueNumber: i,
          year: 2026,
          cite: 'GAMSS/REC/SECRE/CE/$i/2026',
          routeNumber: 'HR-2026-${i.toString().padLeft(6, '0')}',
          type: CorrespondenceTypeCode.ce,
          priority: i.isEven ? 'Baja' : 'Media',
          subject: 'Solicitud administrativa $i',
          externalSender: 'Remitente externo $i',
          externalRecipient: 'Unidad competente $i',
          currentUserName: 'Funcionario $i',
          registeredAt: DateTime(2026, 4, i),
          statusLabel: 'Enviada',
          documentTypeCode: 'CARTA',
          documentTypeName: 'Carta',
          senderDocument: '100000$i',
          senderContact: '7000000$i',
        ),
      );
      derivations.add(
        DerivationEntity(
          id: 'd$i',
          correspondenceId: 'c$i',
          sequenceNumber: 1,
          senderName: 'Lic. JAIME MONTERO LOPEZ',
          recipientName: 'Lic. ANA LUCÍA FLORES ROJAS',
          originUnitName: 'Unidad de Sistemas',
          destinationUnitName: 'Secretaría Municipal',
          instruction: 'Para archivo',
          statusLabel: 'Enviada',
          sentAt: DateTime(2026, 4, i, 14, 0),
          inboxType: InboxType.sent,
        ),
      );
    }
  }

  CorrespondenceEntity? findPublicConsult(PublicConsultRequest request) {
    for (final item in correspondences) {
      final matches = item.uniqueNumber == request.uniqueNumber &&
          item.year == request.year &&
          item.citizenName.toUpperCase().contains(request.fullName.toUpperCase()) &&
          item.citizenDocumentId == request.documentId &&
          item.citizenPhone == request.phone;
      if (matches) return item;
    }
    return null;
  }

  List<DerivationEntity> derivationsByInbox(InboxType type) {
    return derivations.where((item) => item.inboxType == type).toList();
  }

  CorrespondenceEntity? correspondenceById(String id) {
    for (final item in correspondences) {
      if (item.id == id) return item;
    }
    return null;
  }

  CorrespondenceEntity createCorrespondence(CreateCorrespondenceRequest request) {
    final year = DateTime.now().year;
    final uniqueNumber = _nextUniqueNumber++;
    final typeCode = request.type == CorrespondenceTypeCode.ce ? 'CE' : 'CI';
    final correspondence = CorrespondenceEntity(
      id: 'c$_sequence',
      uniqueNumber: uniqueNumber,
      year: year,
      cite: 'GAMSS/REC/SECRE/$typeCode/$uniqueNumber/$year',
      routeNumber:
          'HR-$year-${uniqueNumber.toString().padLeft(6, '0')}',
      type: request.type,
      priority: request.priority,
      subject: request.subject,
      externalSender: request.externalSender,
      externalRecipient: request.externalRecipient,
      currentUserName: request.externalRecipient,
      registeredAt: DateTime.now(),
      statusLabel: 'Registrada',
      documentTypeCode: 'CARTA',
      documentTypeName: 'Carta',
      senderDocument: request.citizenDocumentId,
      senderContact: request.citizenPhone,
    );
    _sequence++;

    correspondences.insert(0, correspondence);

    derivations.insert(
      0,
      DerivationEntity(
        id: 'd$_sequence',
        correspondenceId: correspondence.id,
        sequenceNumber: 1,
        senderName: 'Lic. JAIME MONTERO LOPEZ',
        recipientName: request.externalRecipient,
        originUnitName: 'Recepción',
        destinationUnitName: 'Secretaría Municipal',
        instruction: 'Para atención',
        statusLabel: 'Registrada',
        sentAt: DateTime.now(),
        inboxType: InboxType.inbox,
      ),
    );
    _sequence++;

    return correspondence;
  }

  Map<String, int> inboxCounts() {
    return {
      'received': derivationsByInbox(InboxType.received).length,
      'sent': derivationsByInbox(InboxType.sent).length,
      'inbox': derivationsByInbox(InboxType.inbox).length,
    };
  }
}
