import 'package:blog_app/features/notifications/data/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LikeService {
  final _client = Supabase.instance.client;
  final _notificationService = NotificationService();

  Future<void> likePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client.from('post_likes').insert({
      'post_id': postId,
      'user_id': userId,
    });

    await _notificationService.maybeCreateNotification(
      postId: postId,
      type: 'like',
      actorId: userId,
    );
  }

  Future<void> unlikePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client
        .from('post_likes')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId);
  }

  Future<bool> isPostLikedByCurrentUser(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final rows = await _client
        .from('post_likes')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .limit(1);

    return (rows as List).isNotEmpty;
  }
}
