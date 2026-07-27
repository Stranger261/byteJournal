import 'dart:io';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/widgets/image_view_page.dart';
import 'package:blog_app/features/auth/screens/controllers/auth_controller.dart';
import 'package:blog_app/features/profile/screens/dialogs/remove_avatar_dialog.dart';
import 'package:blog_app/features/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileAvatarSection extends StatelessWidget {
  final String userId;
  final String? name;
  final String? avatarUrl;
  final bool isSaving;

  const ProfileAvatarSection({
    super.key,
    required this.userId,
    required this.name,
    required this.avatarUrl,
    required this.isSaving,
  });

  Future<void> _pickAndUpload(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !context.mounted) return;

    final success = await context.read<ProfileProvider>().updateAvatar(
      userId,
      File(picked.path),
    );
    if (success && context.mounted) {
      await context.read<AuthController>().refreshProfile();
    }
  }

  Future<void> _remove(BuildContext context) async {
    final confirmed = await showRemoveAvatarDialog(context);
    if (!confirmed || !context.mounted) return;

    final success = await context.read<ProfileProvider>().removeAvatar(userId);
    if (success && context.mounted) {
      await context.read<AuthController>().refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final hasAvatar = avatarUrl?.isNotEmpty ?? false;

    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: hasAvatar
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ImageViewerPage(imageUrls: [avatarUrl!]),
                        fullscreenDialog: true,
                      ),
                    )
                  : null,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: c.surfaceAlt,
                    backgroundImage: hasAvatar
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: hasAvatar
                        ? null
                        : Text(
                            (name?.isNotEmpty ?? false)
                                ? name![0].toUpperCase()
                                : '?',
                            style: TextStyle(fontSize: 28, color: c.text),
                          ),
                  ),
                  if (isSaving)
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.45),
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: isSaving ? null : () => _pickAndUpload(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border),
                    shape: BoxShape.circle,
                  ),
                  child: isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.text,
                          ),
                        )
                      : Icon(
                          Icons.camera_alt_outlined,
                          size: 16,
                          color: c.text,
                        ),
                ),
              ),
            ),
          ],
        ),
        if (hasAvatar) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: isSaving ? null : () => _remove(context),
            child: Text(
              'Remove photo',
              style: TextStyle(color: c.muted, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}
