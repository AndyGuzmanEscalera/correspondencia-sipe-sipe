class InternalNotificationResponse {
  const InternalNotificationResponse(
      {required this.id,
      required this.correspondenceId,
      required this.type,
      required this.title,
      required this.message,
      required this.isRead,
      required this.createdAt,
      required this.readAt});
  final String id;
  final String? correspondenceId;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  factory InternalNotificationResponse.fromJson(Map<String, dynamic> json) =>
      InternalNotificationResponse(
        id: json['id'] as String,
        correspondenceId: json['correspondence_id'] as String?,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        isRead: json['is_read'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        readAt: json['read_at'] == null
            ? null
            : DateTime.parse(json['read_at'] as String),
      );
}

class NotificationsPageResponse {
  const NotificationsPageResponse(
      {required this.items,
      required this.total,
      required this.page,
      required this.pageSize,
      required this.totalPages,
      required this.unread});
  final List<InternalNotificationResponse> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final int unread;
  factory NotificationsPageResponse.fromJson(Map<String, dynamic> json) =>
      NotificationsPageResponse(
        items: (json['items'] as List)
            .map((item) => InternalNotificationResponse.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList(),
        total: (json['total'] as num).toInt(),
        page: (json['page'] as num).toInt(),
        pageSize: (json['page_size'] as num).toInt(),
        totalPages: (json['total_pages'] as num).toInt(),
        unread: (json['unread'] as num).toInt(),
      );
}
