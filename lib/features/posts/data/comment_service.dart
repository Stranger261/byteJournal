import 'dart:io';

import 'package:blog_app/features/notifications/data/notification_service.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CommentService {
  final _client = Supabase.instance.client;
  final _notificationService = NotificationService();

  Future<List<CommentModel>> getComments(
    String postId, {
    int page = 0,
    int pageSize = 20,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    final rows = await _client
        .from('post_comments')
        .select(
          '*, comment_images(*), profiles!post_comments_user_id_profiles_fkey(name, avatar_url)',
        )
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .range(from, to);

    return (rows as List).map((r) => CommentModel.fromMap(r)).toList();
  }

  Future<CommentModel> addComment({
    required String postId,
    String? content,
    List<XFile> images = const [],
  }) async {
    if (images.length > 4) {
      throw Exception('A comment can have at most 4 images');
    }
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final hasContent = content != null && content.trim().isNotEmpty;
    if (!hasContent && images.isEmpty) {
      throw Exception('Comment must have text or at least one image');
    }

    final commentRow = await _client
        .from('post_comments')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'content': hasContent ? content.trim() : null,
        })
        .select()
        .single();

    final commentId = commentRow['id'] as String;

    if (images.isNotEmpty) {
      const uuid = Uuid();
      for (var i = 0; i < images.length; i++) {
        final file = images[i];
        final ext = file.path.split('.').last;
        final path = '$userId/comments/$commentId/${uuid.v4()}.$ext';

        await _client.storage.from('post-images').upload(path, File(file.path));

        await _client.from('comment_images').insert({
          'comment_id': commentId,
          'storage_path': path,
          'sort_order': i,
        });
      }
    }

    await _notificationService.maybeCreateNotification(
      postId: postId,
      type: 'comment',
      actorId: userId,
      commentId: commentId,
    );

    final full = await _client
        .from('post_comments')
        .select(
          '*, comment_images(*), profiles!post_comments_user_id_profiles_fkey(name, avatar_url)',
        )
        .eq('id', commentId)
        .single();

    return CommentModel.fromMap(full);
  }

  Future<CommentModel> updateComment({
    required String commentId,
    String? content,
    List<String> existingImageIdsToRemove = const [],
    List<XFile> newImages = const [],
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final existingImages = await _client
        .from('comment_images')
        .select('id, storage_path, sort_order')
        .eq('comment_id', commentId)
        .order('sort_order');

    final remainingExisting = (existingImages as List)
        .where((img) => !existingImageIdsToRemove.contains(img['id']))
        .toList();

    final totalAfterUpdate = remainingExisting.length + newImages.length;
    if (totalAfterUpdate > 4) {
      throw Exception('A comment can have at most 4 images');
    }

    final trimmed = content?.trim();
    final hasContent = trimmed != null && trimmed.isNotEmpty;
    if (!hasContent && totalAfterUpdate == 0) {
      throw Exception('Comment must have text or at least one image');
    }

    final updateResult = await _client
        .from('post_comments')
        .update({'content': hasContent ? trimmed : null})
        .eq('id', commentId)
        .select();

    if ((updateResult as List).isEmpty) {
      throw Exception(
        'Comment update failed — no rows affected (check permissions)',
      );
    }

    for (final imageId in existingImageIdsToRemove) {
      final row = existingImages.firstWhere((img) => img['id'] == imageId);
      await _client.storage.from('post-images').remove([row['storage_path']]);
      await _client.from('comment_images').delete().eq('id', imageId);
    }

    if (newImages.isNotEmpty) {
      const uuid = Uuid();
      var sortOrder = remainingExisting.length;
      for (final file in newImages) {
        final ext = file.path.split('.').last;
        final path = '${user.id}/comments/$commentId/${uuid.v4()}.$ext';
        await _client.storage.from('post-images').upload(path, File(file.path));
        await _client.from('comment_images').insert({
          'comment_id': commentId,
          'storage_path': path,
          'sort_order': sortOrder,
        });
        sortOrder++;
      }
    }

    final commentRow = await _client
        .from('post_comments')
        .select('*, comment_images(*)')
        .eq('id', commentId)
        .single();

    final profile = await _client
        .from('profiles')
        .select('name, avatar_url')
        .eq('id', commentRow['user_id'])
        .maybeSingle();

    return CommentModel(
      id: commentRow['id'],
      postId: commentRow['post_id'],
      userId: commentRow['user_id'],
      content: commentRow['content'],
      createdAt: DateTime.parse(commentRow['created_at']),
      authorName: profile?['name'],
      authorAvatarUrl: profile?['avatar_url'],
      images:
          (commentRow['comment_images'] as List)
              .map((e) => CommentImage.fromMap(e))
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }

  Future<void> deleteComment(String commentId) async {
    final images = await _client
        .from('comment_images')
        .select('storage_path')
        .eq('comment_id', commentId);
    final paths = (images as List)
        .map((i) => i['storage_path'] as String)
        .toList();
    if (paths.isNotEmpty) {
      await _client.storage.from('post-images').remove(paths);
    }
    await _client.from('post_comments').delete().eq('id', commentId);
  }
}
