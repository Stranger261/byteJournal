import 'dart:typed_data';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<XFile> images;
  final bool isSubmitting;
  final VoidCallback onPickImages;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onSubmit;

  const CommentInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.images,
    required this.isSubmitting,
    required this.onPickImages,
    required this.onRemoveImage,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: images.asMap().entries.map((e) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: FutureBuilder<Uint8List>(
                          future: e.value.readAsBytes(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Container(
                                color: Colors.grey.withOpacity(0.15),
                              );
                            }
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => onRemoveImage(e.key),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.black87,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: isSubmitting ? null : onPickImages,
              icon: Icon(Icons.image_outlined, color: c.muted),
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: !isSubmitting,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Write a comment…'),
              ),
            ),
            IconButton(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(Icons.send, color: c.text),
            ),
          ],
        ),
      ],
    );
  }
}
