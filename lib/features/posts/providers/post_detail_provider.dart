import 'package:blog_app/core/services/post_sync_service.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/data/post_service.dart';
import 'package:blog_app/features/posts/data/like_service.dart';
import 'package:blog_app/features/posts/data/share_service.dart';
import 'package:flutter/material.dart';

class PostDetailProvider extends ChangeNotifier {
  final PostService _postService;
  final LikeService _likeService;
  final ShareService _shareService;
  final PostSyncService _syncService;

  final String postId;

  PostDetailProvider({
    required this.postId,
    required PostSyncService syncService,
    PostService? postService,
    LikeService? likeService,
    ShareService? shareService,
  }) : _postService = postService ?? PostService(),
       _likeService = likeService ?? LikeService(),
       _shareService = shareService ?? ShareService(),
       _syncService = syncService;

  PostModel? _post;
  bool _isLoadingPost = true;
  String? _postError;

  bool _isLikeLoading = false;
  bool _isShareLoading = false;

  PostModel? get post => _post;
  bool get isLoadingPost => _isLoadingPost;
  String? get postError => _postError;
  bool get isLikeLoading => _isLikeLoading;
  bool get isShareLoading => _isShareLoading;

  Future<void> loadPost() async {
    _isLoadingPost = true;
    _postError = null;
    notifyListeners();
    try {
      _post = await _postService.getPost(postId);
    } catch (e) {
      _postError = e.toString();
    } finally {
      _isLoadingPost = false;
      notifyListeners();
    }
  }

  void applyUpdatedPost(PostModel updated) {
    _post = updated;
    notifyListeners();
    _syncService.notifyPostUpdated(updated);
  }

  /// Called by CommentsProvider whenever a comment is added/deleted,
  /// so the post's commentCount stays in sync without a full refetch.
  void adjustCommentCount(int delta) {
    if (_post == null) return;
    final next = (_post!.commentCount + delta).clamp(0, 1 << 31);
    _post = _post!.copyWith(commentCount: next);
    notifyListeners();
  }

  Future<void> toggleLike() async {
    if (_post == null || _isLikeLoading) return;
    final wasLiked = _post!.isLikedByCurrentUser;
    final prevCount = _post!.likeCount;

    _isLikeLoading = true;
    _post = _post!.copyWith(
      isLikedByCurrentUser: !wasLiked,
      likeCount: wasLiked ? prevCount - 1 : prevCount + 1,
    );
    notifyListeners();

    try {
      if (wasLiked) {
        await _likeService.unlikePost(postId);
      } else {
        await _likeService.likePost(postId);
      }
      if (_post != null) _syncService.notifyPostUpdated(_post!);
    } catch (_) {
      _post = _post!.copyWith(
        isLikedByCurrentUser: wasLiked,
        likeCount: prevCount,
      );
    } finally {
      _isLikeLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleShare() async {
    if (_post == null || _isShareLoading) return;
    final wasShared = _post!.isSharedByCurrentUser;
    final prevCount = _post!.shareCount;

    _isShareLoading = true;
    _post = _post!.copyWith(
      isSharedByCurrentUser: !wasShared,
      shareCount: wasShared ? prevCount - 1 : prevCount + 1,
    );
    notifyListeners();

    try {
      if (wasShared) {
        await _shareService.unsharePost(postId);
      } else {
        await _shareService.sharePost(postId);
      }
      if (_post != null) _syncService.notifyPostUpdated(_post!);
    } catch (e) {
      try {
        final actuallyShared = await _shareService.isPostSharedByCurrentUser(
          postId,
        );
        _post = _post!.copyWith(
          isSharedByCurrentUser: actuallyShared,
          shareCount: actuallyShared == wasShared
              ? prevCount
              : (actuallyShared ? prevCount + 1 : prevCount - 1),
        );
      } catch (_) {
        _post = _post!.copyWith(
          isSharedByCurrentUser: wasShared,
          shareCount: prevCount,
        );
      }
    } finally {
      _isShareLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePost() async {
    if (_post == null) return false;
    try {
      await _postService.deletePost(_post!.id);
      _syncService.notifyPostDeleted(_post!.id);
      return true;
    } catch (e) {
      return false;
    }
  }
}
