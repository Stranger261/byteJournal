import 'package:flutter/material.dart';

Future<String?> showChangePasswordDialog(
  BuildContext context, {
  required bool isSettingForFirstTime,
}) async {
  final controller = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(isSettingForFirstTime ? 'Set a password' : 'Change password'),
      content: TextField(
        controller: controller,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'New password (min. 8 characters)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
