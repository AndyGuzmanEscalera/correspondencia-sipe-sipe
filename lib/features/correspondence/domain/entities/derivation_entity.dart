import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';

class DerivationEntity extends Equatable {
  const DerivationEntity({
    required this.id,
    required this.correspondenceId,
    required this.sequenceNumber,
    required this.senderName,
    required this.recipientName,
    required this.originUnitName,
    required this.destinationUnitName,
    required this.instruction,
    required this.statusLabel,
    required this.sentAt,
    this.receivedAt,
    this.observation,
    required this.inboxType,
  });

  final String id;
  final String correspondenceId;
  final int sequenceNumber;
  final String senderName;
  final String recipientName;
  final String originUnitName;
  final String destinationUnitName;
  final String instruction;
  final String statusLabel;
  final DateTime sentAt;
  final DateTime? receivedAt;
  final String? observation;
  final InboxType inboxType;

  @override
  List<Object?> get props => [
        id,
        correspondenceId,
        sequenceNumber,
        senderName,
        recipientName,
        originUnitName,
        destinationUnitName,
        instruction,
        statusLabel,
        sentAt,
        receivedAt,
        observation,
        inboxType,
      ];
}
