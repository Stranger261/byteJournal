import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/features/auth/screens/controllers/auth_controller.dart';
import 'package:blog_app/features/profile/screens/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AuthBarAction extends StatelessWidget {
  const AuthBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final auth = context.watch<AuthController>();

    if (!auth.isLoggedIn) {
      return TextButton(
        onPressed: () => context.push(AppRoutes.auth),
        child: const Text('Sign in'),
      );
    }

    final name = auth.profile?.name ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarUrl = auth.profile?.avatarUrl;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ProfilePage())),
        child: CircleAvatar(
          radius: 16,
          backgroundColor: c.surfaceAlt,
          backgroundImage: (avatarUrl?.isNotEmpty ?? false)
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl?.isNotEmpty ?? false)
              ? null
              : Text(initial, style: TextStyle(fontSize: 12, color: c.text)),
        ),
      ),
    );
  }
}
