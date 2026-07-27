import 'package:blog_app/core/services/post_sync_service.dart';
import 'package:blog_app/features/posts/data/like_service.dart';
import 'package:blog_app/features/posts/data/share_service.dart';
import 'package:flutter/material.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/data/post_service.dart';

class MyPostsProvider extends ChangeNotifier {
  final _postService = PostService();
  final _likeService = LikeService();
  final _shareService = ShareService();
  static const _pageSize = 10;

  final String userId;
  final PostSyncService _syncService;

  MyPostsProvider({required this.userId, required PostSyncService syncService})
    : _syncService = syncService {
    _syncService.addListener(_onSyncEvent);
  }

  void _onSyncEvent() {
    final event = _syncService.lastEvent;
    if (event == null) return;

    if (event.action == PostSyncAction.updated) {
      updatePostLocally(event.post!);
    } else {
      removePostLocally(event.postId);
    }
  }

  final List<PostModel> _posts = [];
  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _error;

  List<PostModel> get posts => List.unmodifiable(_posts);
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadInitial() async {
    _page = 0;
    _hasMore = true;
    _posts.clear();
    _error = null;
    notifyListeners();
    await _fetchPage();
  }

  Future<void> refreshPage() async {
    _isRefreshing = true;
    notifyListeners();
    _page = 0;
    _hasMore = true;

    try {
      final fresh = await _postService.getUserPosts(
        userId: userId,
        page: _page,
        pageSize: _pageSize,
      );
      _posts
        ..clear()
        ..addAll(fresh);
      _hasMore = fresh.length == _pageSize;
      _page++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;
    await _fetchPage();
  }

  Future<void> _fetchPage() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newPosts = await _postService.getUserPosts(
        userId: userId,
        page: _page,
        pageSize: _pageSize,
      );
      _posts.addAll(newPosts);
      _hasMore = newPosts.length == _pageSize;
      _page++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final original = _posts[index];
    final wasLiked = original.isLikedByCurrentUser;

    _posts[index] = original.copyWith(
      isLikedByCurrentUser: !wasLiked,
      likeCount: wasLiked ? original.likeCount - 1 : original.likeCount + 1,
    );
    notifyListeners();

    try {
      if (wasLiked) {
        await _likeService.unlikePost(postId);
      } else {
        await _likeService.likePost(postId);
      }
    } catch (e) {
      final revertIndex = _posts.indexWhere((p) => p.id == postId);
      if (revertIndex != -1) {
        _posts[revertIndex] = original;
        notifyListeners();
      }
    }
  }

  Future<void> toggleShare(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final original = _posts[index];
    final wasShared = original.isSharedByCurrentUser;

    _posts[index] = original.copyWith(
      isSharedByCurrentUser: !wasShared,
      shareCount: wasShared ? original.shareCount - 1 : original.shareCount + 1,
    );
    notifyListeners();

    try {
      if (wasShared) {
        await _shareService.unsharePost(postId);
      } else {
        await _shareService.sharePost(postId);
      }
    } catch (e) {
      debugPrint('Toggle share failed: $e');
      final revertIndex = _posts.indexWhere((p) => p.id == postId);
      if (revertIndex != -1) {
        _posts[revertIndex] = original;
        notifyListeners();
      }
    }
  }

  void removePostLocally(String postId) {
    _posts.removeWhere((p) => p.id == postId);
    notifyListeners();
  }

  void updatePostLocally(PostModel updated) {
    final index = _posts.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _posts[index] = updated;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncEvent);
    super.dispose();
  }
}
