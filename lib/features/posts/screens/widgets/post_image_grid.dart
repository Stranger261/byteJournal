import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:flutter/material.dart';

class PostImageGrid extends StatelessWidget {
  final List<PostImage> images;
  final void Function(int index)? onImageTap;
  const PostImageGrid({super.key, required this.images, this.onImageTap});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: switch (images.length) {
        1 => AspectRatio(aspectRatio: 4 / 3, child: _img(images[0], 0)),
        2 => AspectRatio(
          aspectRatio: 16 / 9,
          child: Row(
            children: [
              Expanded(child: _img(images[0], 0)),
              const SizedBox(width: 2),
              Expanded(child: _img(images[1], 1)),
            ],
          ),
        ),
        3 => AspectRatio(
          aspectRatio: 16 / 9,
          child: Row(
            children: [
              Expanded(child: _img(images[0], 0)),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: _img(images[1], 1)),
                    const SizedBox(height: 2),
                    Expanded(child: _img(images[2], 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ => AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: 4,
            itemBuilder: (_, i) {
              if (i == 3 && images.length > 4) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _img(images[3], 3),
                    IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: .5),
                        alignment: Alignment.center,
                        child: Text(
                          '+${images.length - 4}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return _img(images[i], i);
            },
          ),
        ),
      },
    );
  }

  Widget _img(PostImage img, int index) => GestureDetector(
    onTap: onImageTap != null ? () => onImageTap!(index) : null,
    child: Image.network(
      img.publicUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(color: Colors.grey.withOpacity(0.15));
      },
      errorBuilder: (_, __, ___) => Container(
        color: Colors.grey.withOpacity(0.15),
        child: const Icon(Icons.broken_image_outlined),
      ),
    ),
  );
}
