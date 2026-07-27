import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/auth_guard.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/providers/feed_provider.dart';
import 'package:blog_app/features/posts/screens/widgets/post_actions_bar.dart';
import 'package:blog_app/features/posts/screens/widgets/post_image_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback onTap;
  final Future<void> Function(String postId)? onToggleLike;
  final Future<void> Function(String postId)? onToggleShare;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.onToggleLike,
    this.onToggleShare,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLikeLoading = false;
  bool _isShareLoading = false;

  Future<void> _handleLike() async {
    if (_isLikeLoading) return;
    final ok = await requireAuth(context);
    if (!ok || !mounted) return;

    setState(() => _isLikeLoading = true);

    if (widget.onToggleLike != null) {
      await widget.onToggleLike!(widget.post.id);
    } else {
      await context.read<FeedProvider>().toggleLike(widget.post.id);
    }

    if (mounted) setState(() => _isLikeLoading = false);
  }

  Future<void> _handleShare() async {
    if (_isShareLoading) return;
    final ok = await requireAuth(context);
    if (!ok || !mounted) return;

    setState(() => _isShareLoading = true);

    if (widget.onToggleLike != null) {
      await widget.onToggleShare!(widget.post.id);
    } else {
      await context.read<FeedProvider>().toggleShare(widget.post.id);
    }
    if (mounted) setState(() => _isShareLoading = false);
  }

  Future<void> _handleComment() async {
    final ok = await requireAuth(context);
    if (!ok || !mounted) return;
    widget.onTap(); // navigate to detail page — comment box lives there
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final post = widget.post;

    final displayName = (post.authorName?.trim().isNotEmpty ?? false)
        ? post.authorName!.trim()
        : 'Unknown user';
    final avatarInitial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : '?';

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: c.surfaceAlt,
                  backgroundImage: (post.authorAvatarUrl?.isNotEmpty ?? false)
                      ? NetworkImage(post.authorAvatarUrl!)
                      : null,
                  child: (post.authorAvatarUrl?.isNotEmpty ?? false)
                      ? null
                      : Text(
                          avatarInitial,
                          style: TextStyle(fontSize: 12, color: c.text),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: c.text,
                        ),
                      ),
                      Text(
                        timeago.format(post.createdAt),
                        style: TextStyle(fontSize: 11, color: c.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (post.content != null && post.content!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                post.content!,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14, color: c.text, height: 1.4),
              ),
            ],
            if (post.images.isNotEmpty) ...[
              const SizedBox(height: 10),
              PostImageGrid(images: post.images),
            ],
            const SizedBox(height: 10),
            PostActionsBar(
              isLiked: post.isLikedByCurrentUser,
              likeCount: post.likeCount,
              isShared: post.isSharedByCurrentUser,
              shareCount: post.shareCount,
              commentCount: post.commentCount,
              isLikeLoading: _isLikeLoading,
              isShareLoading: _isShareLoading,
              onLikeTap: _handleLike,
              onShareTap: _handleShare,
              onCommentTap: _handleComment,
            ),
          ],
        ),
      ),
    );
  }
}
