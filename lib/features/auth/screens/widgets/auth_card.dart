import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/auth_validators.dart';
import 'package:blog_app/core/widgets/loading_submit_button.dart';
import 'package:blog_app/features/auth/screens/widgets/oauth_button.dart';
import 'package:blog_app/features/auth/screens/widgets/password_requirements.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthCard extends StatelessWidget {
  final DevlogColors colors;
  final bool isDark;
  final bool isLogin;
  final bool showPassword;
  final bool showPasswordChecklist;
  final bool canSubmit;
  final bool isLoading;
  final PasswordValidation passwordValidation;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode passwordFocusNode;
  final VoidCallback onSubmit;
  final VoidCallback onToggleShowPassword;
  final ValueChanged<bool> onSwitchTab;
  final VoidCallback? onGoogleTap;
  final VoidCallback? onGithubTap;
  final VoidCallback? onForgotPassword;

  const AuthCard({
    super.key,
    required this.colors,
    required this.isDark,
    required this.isLogin,
    required this.showPassword,
    required this.showPasswordChecklist,
    required this.canSubmit,
    required this.isLoading,
    required this.passwordValidation,
    required this.emailController,
    required this.passwordController,
    required this.passwordFocusNode,
    required this.onSubmit,
    required this.onToggleShowPassword,
    required this.onSwitchTab,
    this.onGoogleTap,
    this.onGithubTap,
    this.onForgotPassword,
  });

  @override
  Widget build(BuildContext context) {
    final c = colors;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Tabs(
            colors: c,
            isLogin: isLogin,
            onSwitchTab: isLoading ? (_) {} : onSwitchTab,
          ),
          const SizedBox(height: 20),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              isLogin
                  ? 'Sign in to your devlog account.'
                  : 'A few seconds and you are posting.',
              key: ValueKey(isLogin),
              style: TextStyle(fontSize: 13, color: c.secondary),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: emailController,
            enabled: !isLoading,
            decoration: InputDecoration(
              hintText: 'you@company.com',
              prefixIcon: Icon(Icons.mail_outline, size: 18, color: c.muted),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: passwordController,
            focusNode: passwordFocusNode,
            enabled: !isLoading,
            obscureText: !showPassword,
            validator: (value) =>
                AuthValidators.password(value, isLogin: isLogin),
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                onPressed: isLoading ? null : onToggleShowPassword,
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: c.muted,
                ),
              ),
            ),
          ),
          if (!isLogin)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: showPasswordChecklist
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: PasswordRequirements(
                        validation: passwordValidation,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          if (isLogin) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading ? null : onForgotPassword,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(5, 30),
                ),
                child: Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 12, color: c.accent),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          LoadingSubmitButton(
            enabled: canSubmit,
            isLoading: isLoading,
            label: isLogin ? 'Sign in' : 'Create account',
            loadingLabel: isLogin ? 'Signing in…' : 'Creating account…',
            onTap: onSubmit,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: Divider(color: c.border)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'or continue with',
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ),
              Expanded(child: Divider(color: c.border)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: 'Continue with google',
                  child: Opacity(
                    opacity: isLoading ? 0.5 : 1,
                    child: OAuthButton(
                      icon: SvgPicture.asset(
                        'assets/icons/google.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.white : const Color(0xFF1877F2),
                          BlendMode.srcIn,
                        ),
                      ),
                      onTap: isLoading ? () {} : (onGoogleTap ?? () {}),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Tooltip(
                  message: 'Continue with github',
                  child: Opacity(
                    opacity: isLoading ? 0.5 : 1,
                    child: OAuthButton(
                      icon: SvgPicture.asset(
                        'assets/icons/github.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          isDark ? Colors.white : Colors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                      onTap: isLoading ? () {} : (onGithubTap ?? () {}),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final DevlogColors colors;
  final bool isLogin;
  final ValueChanged<bool> onSwitchTab;

  const _Tabs({
    required this.colors,
    required this.isLogin,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _tabButton('Sign in', true),
          _tabButton('Create account', false),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool loginTab) {
    final selected = isLogin == loginTab;
    final c = colors;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSwitchTab(loginTab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? c.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: c.accent.withOpacity(0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? c.text : c.secondary,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
