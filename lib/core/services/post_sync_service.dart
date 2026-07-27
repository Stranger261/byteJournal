// core/services/post_sync_service.dart
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:flutter/foundation.dart';

enum PostSyncAction { updated, deleted }

class PostSyncEvent {
  final PostSyncAction action;
  final String postId;
  final PostModel? post;

  PostSyncEvent.updated(this.post)
    : action = PostSyncAction.updated,
      postId = post!.id;

  PostSyncEvent.deleted(this.postId)
    : action = PostSyncAction.deleted,
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
}
