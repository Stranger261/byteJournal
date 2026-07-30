import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class PostService {
  final _client = Supabase.instance.client;

  Future<PostModel> createPost({
    String? content,
    List<XFile> images = const [],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final hasContent = content != null && content.trim().isNotEmpty;
    if (!hasContent && images.isEmpty) {
      throw Exception('Post must have text or at least one image');
    }

    final postRow = await _client
        .from('posts')
        .insert({'user_id': userId, 'content': content?.trim()})
        .select()
        .single();

    final postId = postRow['id'] as String;

    if (images.isNotEmpty) {
      await _uploadImages(postId: postId, userId: userId, images: images);
    }

    return getPost(postId);
  }

  Future<void> _uploadImages({
    required String postId,
    required String userId,
    required List<XFile> images,
  }) async {
    const uuid = Uuid();
    for (var i = 0; i < images.length; i++) {
      final file = images[i];
      final ext = file.path.split('.').last;
      final path = '$userId/$postId/${uuid.v4()}.$ext';
      final bytes = await file.readAsBytes();

      await _client.storage.from('post-images').uploadBinary(path, bytes);

      await _client.from('post_images').insert({
        'post_id': postId,
        'storage_path': path,
        'sort_order': i,
      });
    }
  }

  Future<List<PostModel>> getUserPosts({
    required String userId,
    int page = 0,
    int pageSize = 10,
  }) async {
    final currentUserId = _client.auth.currentUser?.id;
    final from = page * pageSize;
    final to = from + pageSize - 1;

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
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .range(from, to);

    final posts = (rows as List).map((r) => PostModel.fromMap(r)).toList();

    final postIds = posts.map((p) => p.id).toList();
    if (postIds.isEmpty || currentUserId == null) return posts;

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

  Future<PostModel> getPost(String postId) async {
    final userId = _client.auth.currentUser?.id;

    final row = await _client
        .from('posts')
        .select('''
          *,
          post_images(*),
          profiles!posts_user_id_profiles_fkey(name, avatar_url),
          post_likes(count),
          post_comments(count),
          post_shares(count)
        ''')
        .eq('id', postId)
        .single();

    var post = PostModel.fromMap(row);

    if (userId != null) {
      final likedRows = await _client
          .from('post_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .limit(1);
      final sharedRows = await _client
          .from('post_shares')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', userId)
          .limit(1);

      post = post.copyWith(
        isLikedByCurrentUser: (likedRows as List).isNotEmpty,
        isSharedByCurrentUser: (sharedRows as List).isNotEmpty,
      );
    }

    return post;
  }

  Future<List<PostModel>> getPosts({int page = 0, int pageSize = 10}) async {
    final userId = _client.auth.currentUser?.id;
    final from = page * pageSize;
    final to = from + pageSize - 1;

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
        .order('created_at', ascending: false)
        .range(from, to);

    final posts = (rows as List).map((r) => PostModel.fromMap(r)).toList();

    if (userId == null) return posts;

    final postIds = posts.map((p) => p.id).toList();
    if (postIds.isEmpty) return posts;

    final likedRows = await _client
        .from('post_likes')
        .select('post_id')
        .eq('user_id', userId)
        .inFilter('post_id', postIds);
    final likedIds = (likedRows as List)
        .map((r) => r['post_id'] as String)
        .toSet();

    final sharedRows = await _client
        .from('post_shares')
        .select('post_id')
        .eq('user_id', userId)
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

  Future<void> deleteImage(String imageId, String storagePath) async {
    await _client.storage.from('post-images').remove([storagePath]);
    await _client.from('post_images').delete().eq('id', imageId);
  }

  Future<void> addImagesToPost(
    String postId,
    List<XFile> images,
    int startOrder,
  ) async {
    final userId = _client.auth.currentUser!.id;
    const uuid = Uuid();
    for (var i = 0; i < images.length; i++) {
      final file = images[i];
      final ext = file.path.split('.').last;
      final path = '$userId/$postId/${uuid.v4()}.$ext';
      final bytes = await file.readAsBytes();

      await _client.storage.from('post-images').uploadBinary(path, bytes);

      await _client.from('post_images').insert({
        'post_id': postId,
        'storage_path': path,
        'sort_order': startOrder + i,
      });
    }
  }

  Future<void> updatePostContent(String postId, String? updatedContent) async {
    final trimmed = updatedContent?.trim();
    final result = await _client
        .from('posts')
        .update({
          'content': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId)
        .select();

    if ((result as List).isEmpty) {
      throw Exception(
        'Post update failed — no rows affected (check permissions)',
      );
    }
  }

  Future<void> deletePost(String postId) async {
    final images = await _client
        .from('post_images')
        .select('storage_path')
        .eq('post_id', postId);
    final paths = (images as List)
        .map((i) => i['storage_path'] as String)
        .toList();
    if (paths.isNotEmpty) {
      await _client.storage.from('post-images').remove(paths);
    }
    await _client.from('posts').delete().eq('id', postId);
  }
}
