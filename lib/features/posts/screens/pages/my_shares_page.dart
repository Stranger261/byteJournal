import 'package:blog_app/core/services/post_sync_service.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/widgets/back_to_profilescreen_button.dart';
import 'package:blog_app/features/posts/providers/my_posts_provider.dart';
import 'package:blog_app/features/posts/providers/my_shares_provider.dart';
import 'package:blog_app/features/posts/screens/widgets/my_posts_tab.dart';
import 'package:blog_app/features/posts/screens/widgets/my_shares_tab.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyPostsSharesPage extends StatelessWidget {
  const MyPostsSharesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    final syncService = context.read<PostSyncService>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              MyPostsProvider(userId: userId, syncService: syncService)
                ..loadInitial(),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              MySharesProvider(userId: userId, syncService: syncService)
                ..loadInitial(),
        ),
      ],
      child: const _MyPostsSharesView(),
    );
  }
}

class _MyPostsSharesView extends StatefulWidget {
  const _MyPostsSharesView();

  @override
  State<_MyPostsSharesView> createState() => _MyPostsSharesViewState();
}

class _MyPostsSharesViewState extends State<_MyPostsSharesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: const Text('My Activity'),
        automaticallyImplyLeading: false,
        leading: BackToProfilescreenButton(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: c.accent,
          unselectedLabelColor: c.muted,
          indicatorColor: c.accent,
          tabs: const [
            Tab(text: 'My Posts'),
            Tab(text: 'My Shares'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [MyPostsTab(), MySharesTab()],
      ),
    );
  }
}
