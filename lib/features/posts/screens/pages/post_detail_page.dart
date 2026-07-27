import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/services/post_sync_service.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/auth_guard.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/providers/comments_provider.dart';
import 'package:blog_app/features/posts/providers/post_detail_provider.dart';
import 'package:blog_app/features/posts/screens/widgets/comment_input.dart';
import 'package:blog_app/features/posts/screens/widgets/comment_tile.dart';
import 'package:blog_app/features/posts/screens/widgets/post_actions_bar.dart';
import 'package:blog_app/features/posts/screens/widgets/post_header.dart';
import 'package:blog_app/features/posts/screens/widgets/post_image_grid.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PostDetailPage extends StatelessWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => PostDetailProvider(
            postId: postId,
            syncService: context.read<PostSyncService>(),
          )..loadPost(),
        ),
        ChangeNotifierProxyProvider<PostDetailProvider, CommentsProvider>(
          create: (context) => CommentsProvider(
            postId: postId,
            postDetailProvider: context.read<PostDetailProvider>(),
          )..loadComments(),
          update: (context, postDetailProvider, previous) => previous!,
        ),
      ],
      child: const _PostDetailView(),
    );
  }
}

class _PostDetailView extends StatefulWidget {
  const _PostDetailView();

  @override
  State<_PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<_PostDetailView> {
  final _commentFieldKey = GlobalKey();
  final _commentFocusNode = FocusNode();

  @override
  void dispose() {
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _focusCommentInput() {
    _commentFocusNode.requestFocus();
    final ctx = _commentFieldKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // ---- auth-gated action handlers ----

  Future<void> _handleLike(PostDetailProvider provider) async {
    final ok = await requireAuth(context);
    if (ok) provider.toggleLike();
  }

  Future<void> _handleShare(PostDetailProvider provider) async {
    final ok = await requireAuth(context);
    if (ok) provider.toggleShare();
  }

  Future<void> _handleCommentTap() async {
    final ok = await requireAuth(context);
    if (ok) _focusCommentInput();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PostDetailProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await provider.deletePost();
      if (success && context.mounted) context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final provider = context.watch<PostDetailProvider>();
    final commentsProvider = context.watch<CommentsProvider>();
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: const Text('Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(provider.post),
        ),
      ),
      body: Builder(
        builder: (context) {
          if (provider.isLoadingPost && provider.post == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.postError != null && provider.post == null) {
            return Center(
              child: Text(
                'Failed to load post',
                style: TextStyle(color: c.text),
              ),
            );
          }

          final post = provider.post!;
          final isOwner = post.userId == currentUserId;

          return RefreshIndicator(
            onRefresh: () => Future.wait([
              context.read<PostDetailProvider>().loadPost(),
              context.read<CommentsProvider>().loadComments(),
            ]),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PostHeader(
                    post: post,
                    isOwner: isOwner,
                    onEdit: () async {
                      final result = await context.push<PostModel>(
                        AppRoutes.editPostPath(post.id),
                        extra: post,
                      );
                      if (result != null && context.mounted) {
                        context.read<PostDetailProvider>().applyUpdatedPost(
                          result,
                        );
                      }
                    },
                    onDelete: () => _confirmDelete(context, provider),
                  ),
                  if (post.content != null &&
                      post.content!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      post.content!,
                      style: TextStyle(
                        fontSize: 15,
                        color: c.text,
                        height: 1.5,
                      ),
                    ),
                  ],
                  if (post.images.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    PostImageGrid(
                      images: post.images,
                      onImageTap: (index) {
                        context.push(
                          AppRoutes.imageViewer,
                          extra: {
                            'imageUrls': post.images
                                .map((img) => img.publicUrl)
                                .toList(),
                            'initialIndex': index,
                          },
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  PostActionsBar(
                    isLiked: post.isLikedByCurrentUser,
                    likeCount: post.likeCount,
                    isShared: post.isSharedByCurrentUser,
                    shareCount: post.shareCount,
                    commentCount: post.commentCount,
                    isLikeLoading: provider.isLikeLoading,
                    isShareLoading: provider.isShareLoading,
                    onLikeTap: () => _handleLike(provider),
                    onShareTap: () => _handleShare(provider),
                    onCommentTap: _handleCommentTap,
                  ),
                  const SizedBox(height: 16),
                  Divider(color: c.border),
                  const SizedBox(height: 12),
                  Text(
                    'Comments',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (commentsProvider.isLoadingComments)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (commentsProvider.comments.isEmpty)
                    Text(
                      'No comments yet',
                      style: TextStyle(color: c.muted, fontSize: 13),
                    )
                  else
                    Column(
                      children: commentsProvider.comments
                          .map((comment) => CommentTile(comment: comment))
                          .toList(),
                    ),
                  const SizedBox(height: 16),
                  CommentInput(
                    key: _commentFieldKey,
                    controller: commentsProvider.commentController,
                    focusNode: _commentFocusNode,
                    images: commentsProvider.commentImages,
                    isSubmitting: commentsProvider.isPostingComment,
                    onPickImages: commentsProvider.pickCommentImages,
                    onRemoveImage: commentsProvider.removeCommentImageAt,
                    onSubmit: commentsProvider.submitComment,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
