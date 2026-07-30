import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:flutter/foundation.dart';

enum PostSyncAction { updated, deleted, profileUpdated }

class PostSyncEvent {
  final PostSyncAction action;
  final String? postId;
  final PostModel? post;
  final String? authorId;
  final String? authorName;
  final String? authorAvatarUrl;

  PostSyncEvent.updated(this.post)
    : action = PostSyncAction.updated,
      postId = post!.id,
      authorId = null,
      authorName = null,
      authorAvatarUrl = null;

  PostSyncEvent.deleted(this.postId)
    : action = PostSyncAction.deleted,
      post = null,
      authorId = null,
      authorName = null,
      authorAvatarUrl = null;

  PostSyncEvent.profileUpdated({
    required this.authorId,
    this.authorName,
    this.authorAvatarUrl,
  }) : action = PostSyncAction.profileUpdated,
       postId = null,
       post = null;
}

class PostSyncService extends ChangeNotifier {
  PostSyncEvent? _lastEvent;
  PostSyncEvent? get lastEvent => _lastEvent;

  void notifyPostUpdated(PostModel post) {
    _lastEvent = PostSyncEvent.updated(post);
    notifyListeners();
  }

  void notifyPostDeleted(String postId) {
    _lastEvent = PostSyncEvent.deleted(postId);
    notifyListeners();
  }

  void notifyProfileUpdated(String userId, {String? name, String? avatarUrl}) {
    _lastEvent = PostSyncEvent.profileUpdated(
      authorId: userId,
      authorName: name,
      authorAvatarUrl: avatarUrl,
    );
    notifyListeners();
  }
}
