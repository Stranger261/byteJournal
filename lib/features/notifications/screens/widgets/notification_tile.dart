import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/features/notifications/data/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.mode_comment;
      case 'share':
        return Icons.repeat_rounded;
      default:
        return Icons.notifications;
    }
  }

  Color _iconColor(DevlogColors c) {
    switch (notification.type) {
      case 'like':
        return Colors.red;
      case 'share':
        return c.accent;
      default:
        return c.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notification.isRead ? Colors.transparent : c.accentSoft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: c.surfaceAlt,
              backgroundImage:
                  (notification.actorAvatarUrl?.isNotEmpty ?? false)
                  ? NetworkImage(notification.actorAvatarUrl!)
                  : null,
              child: (notification.actorAvatarUrl?.isNotEmpty ?? false)
                  ? null
                  : Text(
                      (notification.actorName?.isNotEmpty ?? false)
                          ? notification.actorName![0].toUpperCase()
                          : '?',
                      style: TextStyle(color: c.text),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: c.text,
                      height: 1.3,
                    ),
                  ),
                  if (notification.postContentPreview != null &&
                      notification.postContentPreview!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notification.postContentPreview!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.muted),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    timeago.format(notification.createdAt),
                    style: TextStyle(fontSize: 11, color: c.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(_icon, size: 18, color: _iconColor(c)),
          ],
        ),
      ),
    );
  }
}
