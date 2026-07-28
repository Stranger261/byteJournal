import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/widgets/back_to_homescreen_button.dart';
import 'package:blog_app/core/widgets/loading_submit_button.dart';
import 'package:blog_app/features/profile/providers/profile_provider.dart';
import 'package:blog_app/features/profile/screens/widgets/profile_action_tiles.dart';
import 'package:blog_app/features/profile/screens/widgets/profile_avatar_section.dart';
import 'package:blog_app/features/profile/screens/widgets/profile_email_tile.dart';
import 'package:blog_app/features/profile/screens/widgets/profile_name_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return ChangeNotifierProvider(
      create: (_) => ProfileProvider()..load(userId),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (context.mounted) context.pop(AppRoutes.feed);
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final provider = context.watch<ProfileProvider>();

    if (provider.isLoading) {
      return Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(backgroundColor: c.bg),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (provider.profile == null) {
      return Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(backgroundColor: c.bg),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.error ?? 'Could not load profile',
                style: TextStyle(color: c.text),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => provider.load(
                  Supabase.instance.client.auth.currentUser!.id,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final profile = provider.profile!;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        leading: BackToHomeButton(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ProfileAvatarSection(
                userId: profile.id,
                name: profile.name,
                avatarUrl: profile.avatarUrl,
                isSaving: provider.isSaving,
              ),
              const SizedBox(height: 12),
              Divider(color: c.border),
              ProfileNameTile(userId: profile.id, name: profile.name),
              const ProfileEmailTile(),
              const ProfileActionTiles(),
              const SizedBox(height: 24),
              LoadingSubmitButton(
                enabled: true,
                isLoading: false,
                label: 'Sign out',
                loadingLabel: 'Signing out…',
                onTap: () => _signOut(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
