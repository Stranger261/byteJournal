import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/providers/my_shares_provider.dart';
import 'package:blog_app/features/posts/screens/widgets/post_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MySharesTab extends StatefulWidget {
  const MySharesTab({super.key});

  @override
  State<MySharesTab> createState() => _MySharesTabState();
}

class _MySharesTabState extends State<MySharesTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true; // preserve scroll position when switching tabs

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        context.read<MySharesProvider>().loadMore();
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
    super.build(context);
    final c = Theme.of(context).extension<DevlogColors>()!;
    final provider = context.watch<MySharesProvider>();

    return RefreshIndicator(
      onRefresh: () => context.read<MySharesProvider>().refreshPage(),
      child: _buildBody(provider, c),
    );
  }

  Widget _buildBody(MySharesProvider provider, DevlogColors c) {
    if (provider.posts.isEmpty && provider.isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    if (provider.posts.isEmpty && provider.error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!, style: TextStyle(color: c.text)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        context.read<MySharesProvider>().loadInitial(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (provider.posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Text(
                "You haven't posted anything yet",
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
      itemCount: provider.posts.length + 1,
      itemBuilder: (context, index) {
        if (index == provider.posts.length) {
          if (!provider.hasMore) return const SizedBox(height: 40);
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final post = provider.posts[index];
        return PostCard(
          post: post,
          onToggleLike: context.read<MySharesProvider>().toggleLike,
          onToggleShare: context.read<MySharesProvider>().toggleShare,
          onTap: () async {
            final result = await context.push(
              AppRoutes.postDetailPath(post.id),
            );
            if (!context.mounted) return;
            if (result is PostModel) {
              context.read<MySharesProvider>().updatePostLocally(result);
            } else if (result == true) {
              context.read<MySharesProvider>().removePostLocally(post.id);
            }
          },
        );
      },
    );
  }
}
