class DeriveCorrespondenceRequest {
  const DeriveCorrespondenceRequest({
    required this.toUnitId,
    this.toUserId,
    this.instruction,
    this.observation,
  });

  final String toUnitId;
  final String? toUserId;
  final String? instruction;
  final String? observation;

  Map<String, dynamic> toJson() => {
        'to_unit_id': toUnitId,
        if (toUserId != null) 'to_user_id': toUserId,
        if (instruction != null) 'instruction': instruction,
        if (observation != null) 'observation': observation,
      };
}
