import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/data/post_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class UpdatePostProvider extends ChangeNotifier {
  final _postService = PostService();

  late PostModel _originalPost;
  late TextEditingController contentController;

  final List<PostImage> _existingImages = [];
  final Set<String> _imagesToRemove = {};
  final List<XFile> _newImages = [];

  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  List<PostImage> get visibleExistingImages => _existingImages
      .where((img) => !_imagesToRemove.contains(img.id))
      .toList();
  List<XFile> get newImages => _newImages;

  void loadPost(PostModel post) {
    _originalPost = post;
    contentController = TextEditingController(text: post.content ?? '');
    _existingImages
      ..clear()
      ..addAll(post.images);
    _imagesToRemove.clear();
    _newImages.clear();
  }

  void markExistingImageForRemoval(String imageId) {
    _imagesToRemove.add(imageId);
    notifyListeners();
  }

  void undoRemoval(String imageId) {
    _imagesToRemove.remove(imageId);
    notifyListeners();
  }

  void addNewImages(List<XFile> images) {
    _newImages.addAll(images);
    notifyListeners();
  }

  void removeNewImageAt(int index) {
    _newImages.removeAt(index);
    notifyListeners();
  }

  bool get canSubmit {
    final hasText = contentController.text.trim().isNotEmpty;
    final hasImages = visibleExistingImages.isNotEmpty || _newImages.isNotEmpty;
    return (hasText || hasImages) && !_isSubmitting;
  }

  Future<PostModel?> submit() async {
    if (!canSubmit) {
      _error = 'Post needs text or at least one image';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final newContent = contentController.text.trim();
      final contentChanged = newContent != (_originalPost.content ?? '');

      if (contentChanged) {
        await _postService.updatePostContent(
          _originalPost.id,
          newContent.isEmpty ? null : newContent,
        );
      }

      for (final imageId in _imagesToRemove) {
        final image = _existingImages.firstWhere((img) => img.id == imageId);
        await _postService.deleteImage(imageId, image.storagePath);
      }

      if (_newImages.isNotEmpty) {
        final startOrder = visibleExistingImages.length;
        await _postService.addImagesToPost(
          _originalPost.id,
          _newImages,
          startOrder,
        );
      }

      // Always refetch — this is the single source of truth we hand back
      final updated = await _postService.getPost(_originalPost.id);
      return updated;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    contentController.dispose();
    super.dispose();
  }
}
