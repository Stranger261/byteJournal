import 'package:blog_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AddImageTile extends StatelessWidget {
  final VoidCallback onTap;
  const AddImageTile({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          border: Border.all(color: c.border, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.add_photo_alternate_outlined,
          color: c.muted,
          size: 26,
        ),
      ),
    );
  }
}
