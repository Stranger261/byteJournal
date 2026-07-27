import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/services/post_sync_service.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/theme/theme_controller.dart';
import 'package:blog_app/core/widgets/auth_bar_action.dart';
import 'package:blog_app/core/widgets/notification_bell.dart';
import 'package:blog_app/core/widgets/theme_toggle_button.dart';
import 'package:blog_app/features/auth/screens/controllers/auth_controller.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/providers/feed_provider.dart';
import 'package:blog_app/features/posts/screens/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          FeedProvider(syncService: context.read<PostSyncService>())
            ..loadInitial(),
      child: _PostsView(
        onToggleTheme: () => context.read<ThemeController>().toggleTheme(),
      ),
    );
  }
}

class _PostsView extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const _PostsView({required this.onToggleTheme});

  @override
  State<_PostsView> createState() => _PostsViewState();
}

class _PostsViewState extends State<_PostsView> {
  final _scrollController = ScrollController();

  void _handleCreatePostTap(BuildContext context) async {
    final authController = context.read<AuthController>();

    if (!authController.isLoggedIn) {
      await context.push(AppRoutes.auth);
      return;
    }

    final changed = await context.push(AppRoutes.createPost);
    if (changed == true && context.mounted) {
      context.read<FeedProvider>().refreshPage();
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        context.read<FeedProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final feed = context.watch<FeedProvider>();
    final isLoggedIn = context.watch<AuthController>().isLoggedIn;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: const Text('byteJournal'),
        actions: [
          ThemeToggleButton(
            onToggle: () => context.read<ThemeController>().toggleTheme(),
          ),
          const SizedBox(width: 8),
          if (isLoggedIn) ...[
            const NotificationBell(),
            const SizedBox(width: 8),
          ],
          AuthBarAction(),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<FeedProvider>().refreshPage(),
        child: _buildBody(feed, c),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleCreatePostTap(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(FeedProvider feed, DevlogColors c) {
    if (feed.posts.isEmpty && feed.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (feed.posts.isEmpty && feed.error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(feed.error!, style: TextStyle(color: c.text)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          context.read<FeedProvider>().loadInitial(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (feed.posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Text(
                'No posts yet — be the first!',
                style: TextStyle(color: c.muted),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: feed.posts.length + 1,
      itemBuilder: (context, index) {
        if (index == feed.posts.length) {
          if (!feed.hasMore) return const SizedBox(height: 40);
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final post = feed.posts[index];
        return PostCard(
          post: post,
          onTap: () async {
            final result = await context.push(
              AppRoutes.postDetailPath(post.id),
            );
            if (!context.mounted) return;

            if (result is PostModel) {
              context.read<FeedProvider>().updatePostLocally(result);
            } else if (result == true) {
              context.read<FeedProvider>().removePostLocally(post.id);
            }
          },
        );
      },
    );
  }
}
