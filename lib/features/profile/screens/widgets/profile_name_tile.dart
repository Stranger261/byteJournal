import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/features/auth/screens/controllers/auth_controller.dart';
import 'package:blog_app/features/profile/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileNameTile extends StatefulWidget {
  final String userId;
  final String? name;

  const ProfileNameTile({super.key, required this.userId, required this.name});

  @override
  State<ProfileNameTile> createState() => _ProfileNameTileState();
}

class _ProfileNameTileState extends State<ProfileNameTile> {
  final _controller = TextEditingController();
  bool _editing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final success = await context.read<ProfileProvider>().updateName(
      widget.userId,
      name,
    );
    if (success && mounted) {
      setState(() => _editing = false);
      await context.read<AuthController>().refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    if (!_editing && _controller.text != (widget.name ?? '')) {
      _controller.text = widget.name ?? '';
    }

    return ListTile(
      leading: Icon(Icons.person_outline, color: c.muted),
      title: _editing
          ? TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Your name'),
              onSubmitted: (_) => _save(context),
            )
          : Text(
              widget.name ?? 'Add your name',
              style: TextStyle(color: c.text),
            ),
      trailing: _editing
          ? IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => _save(context),
            )
          : IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: () => setState(() => _editing = true),
            ),
    );
  }
}
