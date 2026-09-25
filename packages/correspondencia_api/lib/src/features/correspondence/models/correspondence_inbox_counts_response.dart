class CorrespondenceInboxCountsResponse {
  const CorrespondenceInboxCountsResponse({
    required this.mine,
    required this.unit,
  });

  factory CorrespondenceInboxCountsResponse.fromJson(Map<String, dynamic> json) {
    return CorrespondenceInboxCountsResponse(
      mine: json['mine'] as int? ?? 0,
      unit: json['unit'] as int? ?? 0,
    );
  }

  final int mine;
  final int unit;
}
