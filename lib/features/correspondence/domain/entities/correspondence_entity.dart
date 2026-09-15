import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';

class CorrespondenceEntity extends Equatable {
  const CorrespondenceEntity({
    required this.id,
    required this.uniqueNumber,
    required this.year,
    required this.cite,
    required this.type,
    required this.priority,
    required this.subject,
    required this.externalSender,
    required this.externalRecipient,
    required this.registeredAt,
    required this.statusLabel,
    required this.citizenName,
    required this.citizenDocumentId,
    required this.citizenPhone,
    this.observations,
  });

  final String id;
  final int uniqueNumber;
  final int year;
  final String cite;
  final CorrespondenceTypeCode type;
  final String priority;
  final String subject;
  final String externalSender;
  final String externalRecipient;
  final DateTime registeredAt;
  final String statusLabel;
  final String citizenName;
  final String citizenDocumentId;
  final String citizenPhone;
  final String? observations;

  String get typeLabel =>
      type == CorrespondenceTypeCode.ce ? 'Correspondencia Externa (CE)' : 'Correspondencia Interna (CI)';

  CorrespondenceEntity copyWith({
    String? statusLabel,
    String? observations,
  }) {
    return CorrespondenceEntity(
      id: id,
      uniqueNumber: uniqueNumber,
      year: year,
      cite: cite,
      type: type,
      priority: priority,
      subject: subject,
      externalSender: externalSender,
      externalRecipient: externalRecipient,
      registeredAt: registeredAt,
      statusLabel: statusLabel ?? this.statusLabel,
      citizenName: citizenName,
      citizenDocumentId: citizenDocumentId,
      citizenPhone: citizenPhone,
      observations: observations ?? this.observations,
    );
  }

  @override
  List<Object?> get props => [
        id,
        uniqueNumber,
        year,
        cite,
        type,
        priority,
        subject,
        externalSender,
        externalRecipient,
        registeredAt,
        statusLabel,
        citizenName,
        citizenDocumentId,
        citizenPhone,
        observations,
      ];
}
