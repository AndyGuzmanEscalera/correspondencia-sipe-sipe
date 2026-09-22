import 'package:equatable/equatable.dart';

class CorrespondenceMovement extends Equatable {
  const CorrespondenceMovement({
    required this.id,
    required this.sequenceNumber,
    required this.movementType,
    this.fromUnitName,
    this.fromUserName,
    this.toUnitName,
    this.toUserName,
    this.instruction,
    this.observation,
    required this.createdByUsername,
    required this.createdAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  final String id;
  final int sequenceNumber;
  final String movementType;
  final String? fromUnitName;
  final String? fromUserName;
  final String? toUnitName;
  final String? toUserName;
  final String? instruction;
  final String? observation;
  final String createdByUsername;
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  bool get isCancelled => cancelledAt != null;

  @override
  List<Object?> get props => [
        id,
        sequenceNumber,
        movementType,
        fromUnitName,
        fromUserName,
        toUnitName,
        toUserName,
        instruction,
        observation,
        createdByUsername,
        createdAt,
        cancelledAt,
        cancellationReason,
      ];
}
