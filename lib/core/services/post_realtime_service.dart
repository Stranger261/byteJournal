import 'package:blog_app/core/services/post_sync_service.dart';
import 'package:blog_app/features/posts/data/post_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostRealtimeService {
  final _client = Supabase.instance.client;
  final PostSyncService _syncService;
  final _postService = PostService();

  RealtimeChannel? _channel;

  PostRealtimeService({required PostSyncService syncService})
    : _syncService = syncService;

  void start() {
    _channel = _client
        .channel('post-interactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_likes',
          callback: (payload) => _handleChange(payload, 'post_likes'),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_shares',
          callback: (payload) => _handleChange(payload, 'post_shares'),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_comments',
          callback: (payload) => _handleChange(payload, 'post_comments'),
        )
        .subscribe();
  }

  Future<void> _handleChange(
    PostgresChangePayload payload,
    String table,
  ) async {
    // Every row in these tables has a post_id column — pull it from
    // whichever record is present (insert -> newRecord, delete -> oldRecord).
    final record = payload.newRecord.isNotEmpty
        ? payload.newRecord
        : payload.oldRecord;
    final postId = record['post_id'] as String?;
    if (postId == null) return;

    try {
      // Refetch the post's current counts/state and broadcast it —
      // simplest way to guarantee correctness regardless of insert/delete.
      final updated = await _postService.getPost(postId);
      _syncService.notifyPostUpdated(updated);
    } catch (e) {
      // post might have been deleted concurrently, or fetch failed — ignore
    }
  }

  void stop() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }
}
