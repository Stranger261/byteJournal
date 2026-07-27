import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/data/comment_service.dart';
import 'package:blog_app/features/posts/providers/post_detail_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CommentsProvider extends ChangeNotifier {
  final CommentService _commentService;
  final PostDetailProvider _postDetailProvider;
  final String postId;

  CommentsProvider({
    required this.postId,
    required PostDetailProvider postDetailProvider,
    CommentService? commentService,
  }) : _commentService = commentService ?? CommentService(),
       _postDetailProvider = postDetailProvider;

  List<CommentModel> _comments = [];
  bool _isLoadingComments = false;

  bool _isPostingComment = false;
  final TextEditingController commentController = TextEditingController();
  final List<XFile> _commentImages = [];

  String? _editingCommentId;
  final TextEditingController editCommentController = TextEditingController();
  final List<XFile> editNewImages = [];
  final Set<String> editImageIdsToRemove = {};
  bool isSavingCommentEdit = false;

  List<CommentModel> get comments => List.unmodifiable(_comments);
  bool get isLoadingComments => _isLoadingComments;
  bool get isPostingComment => _isPostingComment;
  List<XFile> get commentImages => List.unmodifiable(_commentImages);
  String? get editingCommentId => _editingCommentId;

  Future<void> loadComments() async {
    _isLoadingComments = true;
    notifyListeners();
    try {
      _comments = await _commentService.getComments(postId);
    } catch (e) {
      debugPrint('Failed to load comments: $e');
    } finally {
      _isLoadingComments = false;
      notifyListeners();
    }
  }

  Future<void> pickCommentImages() async {
    final availableSlots = 4 - _commentImages.length;
    if (availableSlots <= 0) return;

    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      _commentImages.addAll(images);
      notifyListeners();
    }
  }

  void removeCommentImageAt(int index) {
    _commentImages.removeAt(index);
    notifyListeners();
  }

  Future<void> submitComment() async {
    final content = commentController.text.trim();
    if (content.isEmpty && _commentImages.isEmpty) return;
    if (_isPostingComment) return;

    _isPostingComment = true;
    notifyListeners();

    try {
      final comment = await _commentService.addComment(
        postId: postId,
        content: content,
        images: _commentImages,
      );
      _comments = [..._comments, comment];
      commentController.clear();
      _commentImages.clear();
      _postDetailProvider.adjustCommentCount(1);
    } catch (e) {
      debugPrint('Failed to add comment: $e');
    } finally {
      _isPostingComment = false;
      notifyListeners();
    }
  }

  void startEditingComment(CommentModel comment) {
    _editingCommentId = comment.id;
    editCommentController.text = comment.content ?? '';
    editNewImages.clear();
    editImageIdsToRemove.clear();
    notifyListeners();
  }

  void cancelEditingComment() {
    _editingCommentId = null;
    editCommentController.clear();
    editNewImages.clear();
    editImageIdsToRemove.clear();
    notifyListeners();
  }

  void markEditImageForRemoval(String imageId) {
    editImageIdsToRemove.add(imageId);
    notifyListeners();
  }

  void undoEditImageRemoval(String imageId) {
    editImageIdsToRemove.remove(imageId);
    notifyListeners();
  }

  Future<void> pickEditCommentImages() async {
    final comment = _comments.firstWhere((c) => c.id == _editingCommentId);
    final remaining = comment.images.length - editImageIdsToRemove.length;
    final availableSlots = 4 - remaining - editNewImages.length;
    if (availableSlots <= 0) return;

    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isEmpty) return;

    editNewImages.addAll(images.take(availableSlots));
    notifyListeners();
  }

  void removeEditNewImageAt(int index) {
    editNewImages.removeAt(index);
    notifyListeners();
  }

  Future<void> saveCommentEdit() async {
    if (_editingCommentId == null || isSavingCommentEdit) return;

    isSavingCommentEdit = true;
    notifyListeners();

    try {
      final updated = await _commentService.updateComment(
        commentId: _editingCommentId!,
        content: editCommentController.text.trim(),
        existingImageIdsToRemove: editImageIdsToRemove.toList(),
        newImages: editNewImages,
      );

      final index = _comments.indexWhere((c) => c.id == updated.id);
      if (index != -1) {
        _comments = [..._comments]..[index] = updated;
      }

      _editingCommentId = null;
      editCommentController.clear();
      editNewImages.clear();
      editImageIdsToRemove.clear();
    } catch (e) {
      debugPrint('Failed to update comment: $e');
      rethrow;
    } finally {
      isSavingCommentEdit = false;
      notifyListeners();
    }
  }

  Future<bool> deleteComment(String commentId) async {
    try {
      await _commentService.deleteComment(commentId);
      _comments = _comments.where((c) => c.id != commentId).toList();
      _postDetailProvider.adjustCommentCount(-1);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to delete comment: $e');
      return false;
    }
  }

  @override
  void dispose() {
    commentController.dispose();
    editCommentController.dispose();
    super.dispose();
  }
}
