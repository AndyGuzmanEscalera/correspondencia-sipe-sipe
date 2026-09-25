import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';

class CorrespondenceEntity extends Equatable {
  const CorrespondenceEntity({
    required this.id,
    required this.uniqueNumber,
    required this.year,
    required this.cite,
    required this.routeNumber,
    required this.type,
    required this.priority,
    required this.subject,
    required this.registeredAt,
    required this.status,
    required this.statusLabel,
    required this.documentTypeCode,
    required this.documentTypeName,
    this.documentNumber,
    this.reference,
    this.senderName,
    this.currentUnitId,
    this.currentUnitName,
    this.currentUserId,
    this.currentUserName,
    this.currentUserIsActive,
    this.createdByUsername,
    this.description,
    this.originDescription,
    this.originEmployeeName,
    this.originUnitName,
    this.originUserName,
    this.senderDocument,
    this.senderContact,
    this.lastSentAt,
  });

  final String id;
  final int uniqueNumber;
  final int year;
  final String cite;
  final String routeNumber;
  final CorrespondenceTypeCode type;
  final String priority;
  final String subject;
  final DateTime registeredAt;
  final String status;
  final String statusLabel;
  final String documentTypeCode;
  final String documentTypeName;
  final String? documentNumber;
  final String? reference;
  final String? senderName;
  final String? currentUnitId;
  final String? currentUnitName;
  final String? currentUserId;
  final String? currentUserName;
  final bool? currentUserIsActive;
  final String? createdByUsername;
  final String? description;
  final String? originDescription;
  final String? originEmployeeName;
  final String? originUnitName;
  final String? originUserName;
  final String? senderDocument;
  final String? senderContact;
  final DateTime? lastSentAt;

  String get documentTypeLabel => documentTypeName;

  String get originTypeLabel => type == CorrespondenceTypeCode.ce
      ? 'Externa'
      : 'Interna';

  /// Etiqueta larga para detalle (compatibilidad).
  String get typeLabel => type == CorrespondenceTypeCode.ce
      ? 'Correspondencia Externa (CE)'
      : 'Correspondencia Interna (CI)';

  String get currentResponsibleUnitLabel =>
      currentUnitName?.isNotEmpty == true
          ? currentUnitName!
          : 'Sin unidad asignada';

  String get currentResponsibleUserLabel {
    if (currentUserName == null || currentUserName!.isEmpty) {
      return 'Sin responsable asignado';
    }
    if (currentUserIsActive == false) {
      return '${currentUserName!} · Inactivo';
    }
    return currentUserName!;
  }

  String get currentResponsibleLabel =>
      '$currentResponsibleUnitLabel\n$currentResponsibleUserLabel';

  String get originLabel {
    if (type == CorrespondenceTypeCode.ce) {
      return senderName ?? '';
    }
    if (originEmployeeName != null && originEmployeeName!.isNotEmpty) {
      return originEmployeeName!;
    }
    final parts = [originUnitName, originUserName].whereType<String>();
    return parts.join(' / ');
  }

  /// Compatibilidad con mocks de consulta pública / inbox.
  String get citizenName => senderName ?? '';

  String get citizenDocumentId => senderDocument ?? '';

  String get citizenPhone => senderContact ?? '';

  bool get isActiveStatus => status == 'ACTIVE';

  bool get isConcludedStatus => status == 'CONCLUDED';

  bool canManageLifecycle(String? viewerUnitId) {
    final unitId = currentUnitId;
    if (viewerUnitId == null || unitId == null || unitId.isEmpty) {
      return false;
    }
    return viewerUnitId == unitId;
  }

  CorrespondenceEntity copyWith({
    String? status,
    String? statusLabel,
    DateTime? lastSentAt,
  }) {
    return CorrespondenceEntity(
      id: id,
      uniqueNumber: uniqueNumber,
      year: year,
      cite: cite,
      routeNumber: routeNumber,
      type: type,
      priority: priority,
      subject: subject,
      registeredAt: registeredAt,
      status: status ?? this.status,
      statusLabel: statusLabel ?? this.statusLabel,
      documentTypeCode: documentTypeCode,
      documentTypeName: documentTypeName,
      documentNumber: documentNumber,
      reference: reference,
      senderName: senderName,
      currentUnitId: currentUnitId,
      currentUnitName: currentUnitName,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
      currentUserIsActive: currentUserIsActive,
      createdByUsername: createdByUsername,
      description: description,
      originDescription: originDescription,
      originEmployeeName: originEmployeeName,
      originUnitName: originUnitName,
      originUserName: originUserName,
      senderDocument: senderDocument,
      senderContact: senderContact,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        uniqueNumber,
        year,
        cite,
        routeNumber,
        type,
        priority,
        subject,
        registeredAt,
        status,
        statusLabel,
        documentTypeCode,
        documentTypeName,
        documentNumber,
        reference,
        senderName,
        currentUnitId,
        currentUnitName,
        currentUserId,
        currentUserName,
        currentUserIsActive,
        createdByUsername,
        description,
        originDescription,
        originEmployeeName,
        originUnitName,
        originUserName,
        senderDocument,
        senderContact,
        lastSentAt,
      ];
}
