class CorrespondenceSentCountResponse {
  const CorrespondenceSentCountResponse({
    required this.total,
  });

  factory CorrespondenceSentCountResponse.fromJson(Map<String, dynamic> json) {
    return CorrespondenceSentCountResponse(
      total: json['total'] as int? ?? 0,
    );
  }

  final int total;
}
