import 'package:correspondencia_api/correspondencia_api.dart' as api;
import 'entities.dart';

extension InternalNotificationMapping on api.InternalNotificationResponse {
  InternalNotification toEntity() => InternalNotification(
        id: id,
        correspondenceId: correspondenceId,
        type: type,
        title: title,
        message: message,
        isRead: isRead,
        createdAt: createdAt,
        readAt: readAt,
      );
}

extension NotificationsPageMapping on api.NotificationsPageResponse {
  NotificationsPage toEntity() => NotificationsPage(
        items: items.map((item) => item.toEntity()).toList(),
        total: total,
        page: page,
        pageSize: pageSize,
        totalPages: totalPages,
        unread: unread,
      );
}
