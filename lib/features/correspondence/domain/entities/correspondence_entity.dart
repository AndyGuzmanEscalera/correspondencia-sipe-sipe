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
    required this.externalSender,
    required this.externalRecipient,
    required this.currentUserName,
    required this.registeredAt,
    required this.statusLabel,
    required this.documentTypeName,
    this.documentNumber,
    this.reference,
    this.description,
    this.originDescription,
    this.originEmployeeName,
    this.originUnitName,
    this.originUserName,
    this.senderDocument,
    this.senderContact,
  });

  final String id;
  final int uniqueNumber;
  final int year;
  final String cite;
  final String routeNumber;
  final CorrespondenceTypeCode type;
  final String priority;
  final String subject;
  final String externalSender;
  final String externalRecipient;
  final String currentUserName;
  final DateTime registeredAt;
  final String statusLabel;
  final String documentTypeName;
  final String? documentNumber;
  final String? reference;
  final String? description;
  final String? originDescription;
  final String? originEmployeeName;
  final String? originUnitName;
  final String? originUserName;
  final String? senderDocument;
  final String? senderContact;

  String get typeLabel => type == CorrespondenceTypeCode.ce
      ? 'Correspondencia Externa (CE)'
      : 'Correspondencia Interna (CI)';

  String get currentResponsibleLabel {
    if (currentUserName.isNotEmpty) {
      return '$externalRecipient / $currentUserName';
    }
    return externalRecipient;
  }

  String get originLabel {
    if (type == CorrespondenceTypeCode.ce) {
      return externalSender;
    }
    if (originEmployeeName != null && originEmployeeName!.isNotEmpty) {
      return originEmployeeName!;
    }
    final parts = [originUnitName, originUserName].whereType<String>();
    return parts.join(' / ');
  }

  /// Compatibilidad con mocks de consulta pública / inbox.
  String get citizenName => externalSender;

  String get citizenDocumentId => senderDocument ?? '';

  String get citizenPhone => senderContact ?? '';

  CorrespondenceEntity copyWith({
    String? statusLabel,
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
      externalSender: externalSender,
      externalRecipient: externalRecipient,
      currentUserName: currentUserName,
      registeredAt: registeredAt,
      statusLabel: statusLabel ?? this.statusLabel,
      documentTypeName: documentTypeName,
      documentNumber: documentNumber,
      reference: reference,
      description: description,
      originDescription: originDescription,
      originEmployeeName: originEmployeeName,
      originUnitName: originUnitName,
      originUserName: originUserName,
      senderDocument: senderDocument,
      senderContact: senderContact,
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
        externalSender,
        externalRecipient,
        currentUserName,
        registeredAt,
        statusLabel,
        documentTypeName,
        documentNumber,
        reference,
        description,
        originDescription,
        originEmployeeName,
        originUnitName,
        originUserName,
        senderDocument,
        senderContact,
      ];
}
