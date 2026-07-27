import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blog_app/features/posts/data/post_service.dart';

class CreatePostProvider extends ChangeNotifier {
  final _postService = PostService();

  final List<XFile> _selectedImages = [];
  bool _isSubmitting = false;
  String? _error;

  List<XFile> get selectedImages => _selectedImages;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  bool canSubmit(String content) {
    final hasText = content.trim().isNotEmpty;
    return (hasText || _selectedImages.isNotEmpty) && !_isSubmitting;
  }

  void addImages(List<XFile> images) {
    _selectedImages.addAll(images);
    notifyListeners();
  }

  void removeImageAt(int index) {
    _selectedImages.removeAt(index);
    notifyListeners();
  }

  Future<bool> submit(String content) async {
    if (!canSubmit(content)) {
      _error = 'Add some text or at least one image';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      await _postService.createPost(content: content, images: _selectedImages);
      _selectedImages.clear();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
