import 'package:blog_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileEmailTile extends StatelessWidget {
  const ProfileEmailTile({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    return ListTile(
      leading: Icon(Icons.mail_outline, color: c.muted),
      title: Text(
        Supabase.instance.client.auth.currentUser?.email ?? 'No email',
        style: TextStyle(color: c.text),
      ),
      subtitle: Text('Email', style: TextStyle(color: c.muted, fontSize: 11)),
      trailing: Icon(Icons.lock_outline, size: 16, color: c.muted),
      enabled: false,
    );
  }
}
