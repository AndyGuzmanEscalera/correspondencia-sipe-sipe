import 'correspondence_response.dart';

class CorrespondenceListResponse {
  const CorrespondenceListResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory CorrespondenceListResponse.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return CorrespondenceListResponse(
      items: rawItems
          .map(
            (item) => CorrespondenceResponse.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }

  final List<CorrespondenceResponse> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
}
