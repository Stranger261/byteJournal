import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/auth_validators.dart';
import 'package:flutter/material.dart';

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.validation});

  final PasswordValidation validation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RequirementItem(
          passed: validation.minLength,
          text: 'At least 8 characters',
        ),
        _RequirementItem(
          passed: validation.hasUppercase,
          text: 'One uppercase letter',
        ),
        _RequirementItem(
          passed: validation.hasLowercase,
          text: 'One lowercase letter',
        ),
        _RequirementItem(passed: validation.hasNumber, text: 'One number'),
        _RequirementItem(
          passed: validation.hasSpecialCharacter,
          text: 'One special character',
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  const _RequirementItem({required this.passed, required this.text});

  final bool passed;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    final color = passed ? c.success : c.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Icon(
              passed ? Icons.check_circle_rounded : Icons.circle_outlined,
              key: ValueKey(passed),
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                color: passed ? c.text : c.secondary,
                fontWeight: passed ? FontWeight.w500 : FontWeight.w400,
              ),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}
