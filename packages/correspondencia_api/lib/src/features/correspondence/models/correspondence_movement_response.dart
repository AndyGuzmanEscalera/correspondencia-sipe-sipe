class CorrespondenceMovementResponse {
  const CorrespondenceMovementResponse({
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

  factory CorrespondenceMovementResponse.fromJson(Map<String, dynamic> json) {
    return CorrespondenceMovementResponse(
      id: json['id'] as String,
      sequenceNumber: json['sequence_number'] as int,
      movementType: json['movement_type'] as String,
      fromUnitName: json['from_unit_name'] as String?,
      fromUserName: json['from_user_name'] as String?,
      toUnitName: json['to_unit_name'] as String?,
      toUserName: json['to_user_name'] as String?,
      instruction: json['instruction'] as String?,
      observation: json['observation'] as String?,
      createdByUsername: json['created_by_username'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
    );
  }

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
}
