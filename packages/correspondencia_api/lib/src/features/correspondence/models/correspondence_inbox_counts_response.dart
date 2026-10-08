class CorrespondenceInboxCountsResponse {
  const CorrespondenceInboxCountsResponse({
    required this.mine,
    required this.unit,
    this.canViewUnitCorrespondence = false,
  });

  factory CorrespondenceInboxCountsResponse.fromJson(
      Map<String, dynamic> json) {
    return CorrespondenceInboxCountsResponse(
      mine: json['mine'] as int? ?? 0,
      unit: json['unit'] as int? ?? 0,
      canViewUnitCorrespondence:
          json['can_view_unit_correspondence'] as bool? ?? false,
    );
  }

  final int mine;
  final int unit;
  final bool canViewUnitCorrespondence;
}
