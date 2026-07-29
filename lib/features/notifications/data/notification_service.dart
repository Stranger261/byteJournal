import 'package:blog_app/features/notifications/data/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final _client = Supabase.instance.client;

  Future<void> maybeCreateNotification({
    required String postId,
    required String type,
    required String actorId,
    String? commentId,
  }) async {
    final post = await _client
        .from('posts')
        .select('user_id')
        .eq('id', postId)
        .single();
    final recipientId = post['user_id'] as String;

    if (recipientId == actorId) return; // don't notify yourself

    if (type == 'like') {
      final existing = await _client
          .from('notifications')
          .select('id')
          .eq('recipient_id', recipientId)
          .eq('actor_id', actorId)
          .eq('post_id', postId)
          .eq('type', 'like')
          .maybeSingle();

      if (existing != null)
        return; // already notified for this like relationship
    }

    await _client.from('notifications').insert({
      'recipient_id': recipientId,
      'actor_id': actorId,
      'type': type,
      'post_id': postId,
      'comment_id': commentId,
    });
  }

  Future<List<NotificationModel>> getNotifications({
    int page = 0,
    int pageSize = 20,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final from = page * pageSize;
    final to = from + pageSize - 1;

    final rows = await _client
        .from('notifications')
        .select('''
          *,
          actor:profiles!notifications_actor_id_profiles_fkey(name, avatar_url),
          post:posts!notifications_post_id_fkey(content)
        ''')
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);

    return (rows as List).map((r) => NotificationModel.fromMap(r)).toList();
  }

  Future<NotificationModel?> getNotificationById(String id) async {
    final row = await _client
        .from('notifications')
        .select('''
        *,
        actor:profiles!notifications_actor_id_profiles_fkey(name, avatar_url),
        post:posts!notifications_post_id_fkey(content)
      ''')
        .eq('id', id)
        .maybeSingle();

    return row == null ? null : NotificationModel.fromMap(row);
  }

  Future<int> getUnreadCount() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return 0;

    final rows = await _client
        .from('notifications')
        .select('id')
        .eq('recipient_id', userId)
        .eq('is_read', false);

    return (rows as List).length;
  }

  Future<void> markAsRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> markAllAsRead() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client
        .from('notifications')
        .update({'is_read': true})
        .eq('recipient_id', userId)
        .eq('is_read', false);
  }
}
