import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/toast.dart';
import 'package:go_router/go_router.dart';
import 'package:blog_app/features/profile/providers/profile_provider.dart';
import 'package:blog_app/features/profile/screens/dialogs/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool get _hasPasswordAuth =>
    Supabase.instance.client.auth.currentUser?.identities?.any(
      (i) => i.provider == 'email',
    ) ??
    false;

class ProfileActionTiles extends StatefulWidget {
  const ProfileActionTiles({super.key});

  @override
  State<ProfileActionTiles> createState() => _ProfileActionTilesState();
}

class _ProfileActionTilesState extends State<ProfileActionTiles> {
  Future<void> _changePassword(BuildContext context) async {
    final isSettingForFirstTime = !_hasPasswordAuth;
    final newPassword = await showChangePasswordDialog(
      context,
      isSettingForFirstTime: isSettingForFirstTime,
    );

    if (newPassword == null || !context.mounted) return;

    if (newPassword.trim().length < 8) {
      DevlogToast.show(
        context,
        'Password must be at least 8 characters',
        type: ToastType.error,
      );
      return;
    }

    final success = await context.read<ProfileProvider>().changePassword(
      newPassword.trim(),
    );

    if (context.mounted) {
      DevlogToast.show(
        context,
        success
            ? (isSettingForFirstTime
                  ? 'Password set — you can now sign in with email too'
                  : 'Password updated')
            : 'Failed to update password',
        type: success ? ToastType.success : ToastType.error,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.article_outlined, color: c.muted),
          title: const Text('My Posts and Shares'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(AppRoutes.myPostsShare),
        ),
        ListTile(
          leading: Icon(Icons.lock_outline, color: c.muted),
          title: Text(_hasPasswordAuth ? 'Change password' : 'Set a password'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _changePassword(context),
        ),
      ],
    );
  }
}
