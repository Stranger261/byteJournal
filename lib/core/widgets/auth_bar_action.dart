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

    final profile = auth.profile;
    final name = profile?.name ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final avatarUrl = profile?.avatarUrl;
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: GestureDetector(
        onTap: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));

          // Refresh after returning from ProfilePage
          await context.read<AuthController>().refreshProfile();
        },
        child: CircleAvatar(
          radius: 16,
          backgroundColor: c.surfaceAlt,
          backgroundImage: hasAvatar
              ? NetworkImage(
                  '$avatarUrl?v=${DateTime.now().millisecondsSinceEpoch}',
                )
              : null,
          child: hasAvatar
              ? null
              : Text(initial, style: TextStyle(fontSize: 12, color: c.text)),
        ),
      ),
    );
  }
}
