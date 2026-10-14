class InternalNotification {
  const InternalNotification(
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
}

class NotificationsPage {
  const NotificationsPage(
      {required this.items,
      required this.total,
      required this.page,
      required this.pageSize,
      required this.totalPages,
      required this.unread});
  final List<InternalNotification> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final int unread;
}
