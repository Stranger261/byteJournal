import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostHeader extends StatelessWidget {
  final PostModel post;
  final bool isOwner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PostHeader({
    super.key,
    required this.post,
    required this.isOwner,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: c.surfaceAlt,
          backgroundImage: (post.authorAvatarUrl?.isNotEmpty ?? false)
              ? NetworkImage(post.authorAvatarUrl!)
              : null,
          child: (post.authorAvatarUrl?.isNotEmpty ?? false)
              ? null
              : Text(
                  (post.authorName?.isNotEmpty ?? false)
                      ? post.authorName![0].toUpperCase()
                      : '?',
                  style: TextStyle(color: c.text),
                ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.authorName ?? 'Unknown user',
                style: TextStyle(fontWeight: FontWeight.w600, color: c.text),
              ),
              Text(
                timeago.format(post.createdAt),
                style: TextStyle(fontSize: 12, color: c.muted),
              ),
            ],
          ),
        ),
        if (isOwner)
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
      ],
    );
  }
}
