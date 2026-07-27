import 'package:blog_app/core/services/post_sync_service.dart';
import 'package:blog_app/features/posts/data/like_service.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/data/share_service.dart';
import 'package:flutter/material.dart';

class MySharesProvider extends ChangeNotifier {
  final _likeService = LikeService();
  final _shareService = ShareService();
  static const _pageSize = 10;

  final String userId;
  final PostSyncService _syncService;

  MySharesProvider({required this.userId, required PostSyncService syncService})
    : _syncService = syncService {
    _syncService.addListener(_onSyncEvent);
  }

  void _onSyncEvent() {
    final event = _syncService.lastEvent;
    if (event == null) return;

    if (event.action == PostSyncAction.updated) {
      final updated = event.post!;
      // If it was un-shared elsewhere, drop it from this list entirely.
      if (!updated.isSharedByCurrentUser) {
        removePostLocally(updated.id);
      } else {
        updatePostLocally(updated);
      }
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
    _page = 0;
    _hasMore = true;
    await _fetchPage(isRefresh: true);
  }

  Future<void> loadMore() async {
    if (_isLoading || _isRefreshing || !_hasMore) return;
    await _fetchPage();
  }

  Future<void> _fetchPage({bool isRefresh = false}) async {
    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    _error = null;
    notifyListeners();

    try {
      final newPosts = await _shareService.getSharedPosts(
        userId: userId,
        page: _page,
        pageSize: _pageSize,
      );
      if (isRefresh) {
        _posts
          ..clear()
          ..addAll(newPosts);
      } else {
        _posts.addAll(newPosts);
      }
      _hasMore = newPosts.length == _pageSize;
      _page++;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (isRefresh) {
        _isRefreshing = false;
      } else {
        _isLoading = false;
      }
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
      _syncService.notifyPostUpdated(_posts[index]);
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
        // Unsharing from within "My Shares" should remove it from this list.
        removePostLocally(postId);
      } else {
        await _shareService.sharePost(postId);
        _syncService.notifyPostUpdated(_posts[index]);
      }
    } catch (e) {
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
