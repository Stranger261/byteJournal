import 'package:blog_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class PostActionsBar extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final bool isShared;
  final int shareCount;
  final int commentCount;
  final bool isLikeLoading;
  final bool isShareLoading;
  final VoidCallback onLikeTap;
  final VoidCallback onShareTap;
  final VoidCallback? onCommentTap;

  const PostActionsBar({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.isShared,
    required this.shareCount,
    required this.commentCount,
    required this.onLikeTap,
    required this.onShareTap,
    this.onCommentTap,
    this.isLikeLoading = false,
    this.isShareLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: isLiked ? Colors.red : c.muted,
          label: likeCount > 0 ? '$likeCount' : 'Like',
          textColor: c.muted,
          onTap: isLikeLoading ? null : onLikeTap,
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.mode_comment_outlined,
          iconColor: c.muted,
          label: commentCount > 0 ? '$commentCount' : 'Comment',
          textColor: c.muted,
          onTap: onCommentTap,
        ),
        const SizedBox(width: 20),
        _ActionButton(
          icon: Icons.repeat_rounded,
          iconColor: isShared ? primary : c.muted,
          label: shareCount > 0 ? '$shareCount' : 'Share',
          textColor: c.muted,
          onTap: isShareLoading ? null : onShareTap,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color textColor;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 13, color: textColor)),
          ],
        ),
      ),
    );
  }
}
