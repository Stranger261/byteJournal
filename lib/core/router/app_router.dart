import 'dart:async';

import 'package:blog_app/core/widgets/image_view_page.dart';
import 'package:blog_app/features/auth/screens/pages/auth_screen.dart';
import 'package:blog_app/features/auth/screens/pages/otp_screen.dart';
import 'package:blog_app/features/auth/screens/pages/reset_password_screen.dart';
import 'package:blog_app/features/notifications/screens/pages/notification_page.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/screens/pages/create_post_page.dart';
import 'package:blog_app/features/posts/screens/pages/my_shares_page.dart';
import 'package:blog_app/features/posts/screens/pages/post_detail_page.dart';
import 'package:blog_app/features/posts/screens/pages/posts_page.dart';
import 'package:blog_app/features/posts/screens/pages/update_post_page.dart';
import 'package:blog_app/features/profile/screens/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bridges a Stream (Supabase auth state changes) into a Listenable so
/// GoRouter's `redirect` re-runs whenever auth state changes, not just
/// on navigation events.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRoutes {
  static const feed = '/posts';
  static const auth = '/auth';
  static const authOtp = '/auth/otop';
  static const postDetail = '/post/:id';
  static const createPost = '/posts/create';
  static const editPost = '/post/:id/edit';
  static const profile = '/profile';
  static const myPostsShare = '/profile/my-posts';
  static const imageViewer = '/image-viewer';
  static const resetPassword = '/reset-password';
  static const notifications = '/notifications';

  static String postDetailPath(String id) => '/post/$id';
  static String editPostPath(String id) => '/post/$id/edit';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.feed,
  refreshListenable: GoRouterRefreshStream(
    Supabase.instance.client.auth.onAuthStateChange,
  ),
  redirect: (context, state) {
    final isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    final isGoingToAuth =
        state.matchedLocation == AppRoutes.auth ||
        state.matchedLocation == AppRoutes.authOtp ||
        state.matchedLocation == AppRoutes.resetPassword;

    // state.fullPath is the route *template* (e.g. '/post/:id'),
    // not the resolved path (e.g. '/post/123') — needed for dynamic routes.
    final isPublicPage =
        state.fullPath == AppRoutes.feed ||
        state.fullPath == AppRoutes.postDetail;

    // Not logged in and trying to reach a protected page -> send to /auth
    if (!isLoggedIn && !isGoingToAuth && !isPublicPage) {
      return AppRoutes.auth;
    }

    // Already logged in but sitting on the auth screen -> send to feed
    if (isLoggedIn && isGoingToAuth) {
      return AppRoutes.feed;
    }

    return null; // no redirect needed
  },
  routes: [
    GoRoute(
      path: AppRoutes.feed,
      builder: (context, state) => const PostsPage(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => const AuthScreen(),
    ),
    GoRoute(
      path: AppRoutes.authOtp,
      builder: (context, state) {
        final email = state.extra as String;
        return OtpVerificationScreen(email: email);
      },
    ),
    GoRoute(
      path: AppRoutes.postDetail,
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PostDetailPage(postId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.createPost,
      builder: (context, state) => const CreatePostPage(),
    ),
    GoRoute(
      path: AppRoutes.editPost,
      builder: (context, state) {
        final post = state.extra as PostModel;
        return UpdatePostPage(post: post);
      },
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfilePage(),
    ),
    GoRoute(
      path: AppRoutes.myPostsShare,
      builder: (context, state) => const MyPostsSharesPage(),
    ),
    GoRoute(
      path: AppRoutes.imageViewer,
      pageBuilder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return MaterialPage(
          fullscreenDialog: true,
          child: ImageViewerPage(
            imageUrls: data['imageUrls'] as List<String>,
            initialIndex: data['initialIndex'] as int? ?? 0,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (context, state) => const ResetPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsPage(),
    ),
  ],
);
