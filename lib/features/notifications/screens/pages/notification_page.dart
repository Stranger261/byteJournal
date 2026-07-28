// features/notifications/screens/pages/notifications_page.dart
import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/widgets/back_to_homescreen_button.dart';
import 'package:blog_app/features/notifications/providers/notifications_provider.dart';
import 'package:blog_app/features/notifications/screens/widgets/notification_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300) {
        context.read<NotificationsProvider>().loadMore();
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
    final provider = context.watch<NotificationsProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: c.bg,
        title: const Text('Notifications'),
        leading: BackToHomeButton(),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () =>
                  context.read<NotificationsProvider>().markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<NotificationsProvider>().refreshPage(),
        child: _buildBody(provider, c),
      ),
    );
  }

  Widget _buildBody(NotificationsProvider provider, DevlogColors c) {
    if (provider.notifications.isEmpty && provider.isLoading) {
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

    if (provider.notifications.isEmpty && provider.error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(provider.error!, style: TextStyle(color: c.text)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        context.read<NotificationsProvider>().loadInitial(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (provider.notifications.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Text(
                'No notifications yet',
                style: TextStyle(color: c.muted),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: provider.notifications.length + 1,
      separatorBuilder: (_, __) => Divider(height: 1, color: c.border),
      itemBuilder: (context, index) {
        if (index == provider.notifications.length) {
          if (!provider.hasMore) return const SizedBox(height: 40);
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final notification = provider.notifications[index];
        return NotificationTile(
          notification: notification,
          onTap: () {
            context.read<NotificationsProvider>().markAsRead(notification.id);
            context.push(AppRoutes.postDetailPath(notification.postId));
          },
        );
      },
    );
  }
}
