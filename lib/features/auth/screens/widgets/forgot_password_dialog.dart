import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/auth_validators.dart';
import 'package:blog_app/features/auth/data/auth_service.dart';
import 'package:flutter/material.dart';

Future<void> showForgotPasswordDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => const _ForgotPasswordDialog(),
  );
}

class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog();

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (AuthValidators.email(email) != null) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AuthService().sendPasswordResetEmail(email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    return AlertDialog(
      backgroundColor: c.surface,
      title: Text(
        _sent ? 'Check your email' : 'Reset password',
        style: TextStyle(color: c.text),
      ),
      content: _sent
          ? Text(
              'If an account exists for that email, a reset link has been sent.',
              style: TextStyle(color: c.muted, fontSize: 13.5, height: 1.4),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter your email and we'll send you a reset link.",
                  style: TextStyle(color: c.muted, fontSize: 13),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _emailController,
                  enabled: !_isLoading,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: TextStyle(color: c.danger, fontSize: 12),
                  ),
                ],
              ],
            ),
      actions: [
        if (_sent)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          )
        else ...[
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Send link'),
          ),
        ],
      ],
    );
  }
}
