import 'package:blog_app/features/notifications/data/notification_service.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ShareService {
  final _client = Supabase.instance.client;
  final _notificationService = NotificationService();

  Future<void> sharePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await _client.from('post_shares').insert({
        'post_id': postId,
        'user_id': userId,
      });

      await _notificationService.maybeCreateNotification(
        postId: postId,
        type: 'share',
        actorId: userId,
      );
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // already shared — not a real error, treat as success
        return;
      }
      rethrow;
    }
  }

  Future<void> unsharePost(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final result = await _client
        .from('post_shares')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', userId)
        .select();

    if ((result as List).isEmpty) {
      throw Exception('Unshare failed — no rows affected (check permissions)');
    }
  }

  Future<bool> isPostSharedByCurrentUser(String postId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    final rows = await _client
        .from('post_shares')
        .select('id')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .limit(1);

    return (rows as List).isNotEmpty;
  }

  Future<List<PostModel>> getSharedPosts({
    required String userId,
    int page = 0,
    int pageSize = 10,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final shareRows = await _client
        .from('post_shares')
        .select('post_id, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);

    final sharedPostIds = (shareRows as List)
        .map((r) => r['post_id'] as String)
        .toList();

    if (sharedPostIds.isEmpty) return [];

    final rows = await _client
        .from('posts')
        .select('''
        *,
        post_images(*),
        profiles!posts_user_id_profiles_fkey(name, avatar_url),
        post_likes(count),
        post_comments(count),
        post_shares(count)
      ''')
        .inFilter('id', sharedPostIds);

    final postsById = {
      for (final r in (rows as List)) r['id'] as String: PostModel.fromMap(r),
    };

    final posts = sharedPostIds
        .where((id) => postsById.containsKey(id))
        .map((id) => postsById[id]!)
        .toList();

    if (currentUserId == null) return posts;

    final postIds = posts.map((p) => p.id).toList();

    final likedRows = await _client
        .from('post_likes')
        .select('post_id')
        .eq('user_id', currentUserId)
        .inFilter('post_id', postIds);
    final likedIds = (likedRows as List)
        .map((r) => r['post_id'] as String)
        .toSet();

    final sharedRows = await _client
        .from('post_shares')
        .select('post_id')
        .eq('user_id', currentUserId)
        .inFilter('post_id', postIds);
    final sharedIds = (sharedRows as List)
        .map((r) => r['post_id'] as String)
        .toSet();

    return posts.map((p) {
      return p.copyWith(
        isLikedByCurrentUser: likedIds.contains(p.id),
        isSharedByCurrentUser: sharedIds.contains(p.id),
      );
    }).toList();
  }
}
