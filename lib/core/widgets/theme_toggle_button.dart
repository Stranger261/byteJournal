import 'package:blog_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ThemeToggleButton extends StatelessWidget {
  final VoidCallback onToggle;
  const ThemeToggleButton({super.key, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
          size: 17,
          color: c.text,
        ),
      ),
    );
  }
}
