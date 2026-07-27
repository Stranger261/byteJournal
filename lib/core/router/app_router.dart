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

class AppRoutes {
  static const feed = '/';
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
