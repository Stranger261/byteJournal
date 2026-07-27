import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OAuthButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const OAuthButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: c.border),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: SizedBox(width: 20, height: 20, child: icon),
    );
  }
}
