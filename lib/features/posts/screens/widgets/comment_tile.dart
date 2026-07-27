import 'dart:io';

import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/toast.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/providers/comments_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class CommentTile extends StatelessWidget {
  final CommentModel comment;
  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final provider = context.watch<CommentsProvider>();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isOwner = comment.userId == currentUserId;
    final isEditing = provider.editingCommentId == comment.id;

    if (isEditing) {
      return _EditingCommentTile(comment: comment);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: c.surfaceAlt,
            backgroundImage: (comment.authorAvatarUrl?.isNotEmpty ?? false)
                ? NetworkImage(comment.authorAvatarUrl!)
                : null,
            child: (comment.authorAvatarUrl?.isNotEmpty ?? false)
                ? null
                : Text(
                    (comment.authorName?.isNotEmpty ?? false)
                        ? comment.authorName![0].toUpperCase()
                        : '?',
                    style: TextStyle(fontSize: 11, color: c.text),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            comment.authorName ?? 'Unknown user',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: c.text,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timeago.format(comment.createdAt),
                            style: TextStyle(fontSize: 11, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    if (isOwner)
                      PopupMenuButton<String>(
                        iconSize: 16,
                        padding: EdgeInsets.zero,
                        onSelected: (value) async {
                          if (value == 'edit') {
                            provider.startEditingComment(comment);
                          } else if (value == 'delete') {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete comment?'),
                                content: const Text('This cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              provider.deleteComment(comment.id);
                            }
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                  ],
                ),
                if (comment.content != null &&
                    comment.content!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    comment.content!,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: c.text,
                      height: 1.4,
                    ),
                  ),
                ],
                if (comment.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: comment.images.asMap().entries.map((entry) {
                      final index = entry.key;
                      final img = entry.value;
                      return GestureDetector(
                        onTap: () {
                          context.push(
                            AppRoutes.imageViewer,
                            extra: {
                              'imageUrls': comment.images
                                  .map((i) => i.publicUrl)
                                  .toList(),
                              'initialIndex': index,
                            },
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            img.publicUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditingCommentTile extends StatelessWidget {
  final CommentModel comment;
  const _EditingCommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final provider = context.watch<CommentsProvider>();

    final visibleExisting = comment.images
        .where((img) => !provider.editImageIdsToRemove.contains(img.id))
        .toList();
    final totalImages = visibleExisting.length + provider.editNewImages.length;
    final canAddMore = totalImages < 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: provider.editCommentController,
            enabled: !provider.isSavingCommentEdit,
            minLines: 1,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Edit comment…'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...visibleExisting.map(
                (img) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img.publicUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => provider.markEditImageForRemoval(img.id),
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
                ),
              ),
              ...provider.editNewImages.asMap().entries.map(
                (e) => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(e.value.path),
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => provider.removeEditNewImageAt(e.key),
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
                ),
              ),
              if (canAddMore && !provider.isSavingCommentEdit)
                GestureDetector(
                  onTap: provider.pickEditCommentImages,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: c.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: provider.isSavingCommentEdit
                    ? null
                    : provider.cancelEditingComment,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 4),
              FilledButton(
                onPressed: provider.isSavingCommentEdit
                    ? null
                    : () async {
                        try {
                          await provider.saveCommentEdit();
                        } catch (e) {
                          if (context.mounted) {
                            DevlogToast.show(
                              context,
                              e.toString(),
                              type: ToastType.error,
                            );
                          }
                        }
                      },
                child: provider.isSavingCommentEdit
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
