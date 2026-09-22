class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) fromJsonT,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return PaginatedResponse<T>(
      items: rawItems
          .map(
            (item) => fromJsonT((item as Map).cast<String, dynamic>()),
          )
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 20,
      total: json['total'] as int? ?? 0,
      totalPages: json['total_pages'] as int? ?? 0,
    );
  }

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;
  final int totalPages;
}
