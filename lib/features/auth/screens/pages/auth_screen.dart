import 'dart:async';

import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/theme/theme_controller.dart';
import 'package:blog_app/core/utils/auth_validators.dart';
import 'package:blog_app/core/utils/toast.dart';
import 'package:blog_app/core/widgets/brand_mark.dart';
import 'package:blog_app/core/widgets/theme_toggle_button.dart';
import 'package:blog_app/features/auth/data/auth_service.dart';
import 'package:blog_app/features/auth/screens/widgets/auth_card.dart';
import 'package:blog_app/features/auth/screens/widgets/forgot_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  // OAuth
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  late final StreamSubscription<AuthState> _authSub;

  PasswordValidation passwordValidation = AuthValidators.passwordRequirements(
    '',
  );

  bool _showPasswordChecklist = false;
  bool isLogin = true;
  bool showPassword = false;
  bool _isLoading = false;

  // Entrance animation so the card settles in instead of just appearing.
  late final AnimationController _introController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  )..forward();

  late final Animation<double> _fadeIn = CurvedAnimation(
    parent: _introController,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slideIn =
      Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
        CurvedAnimation(parent: _introController, curve: Curves.easeOutCubic),
      );

  void goToFeed() {
    debugPrint('OAUTH: goToFeed called, context.mounted=$mounted');
    try {
      context.go(AppRoutes.feed);
      debugPrint('OAUTH: context.go succeeded');
    } catch (e, stack) {
      debugPrint('OAUTH: context.go threw: $e');
      debugPrint('OAUTH: stack: $stack');
    }
  }

  void login() async {
    if (_isLoading) return;

    final email = _emailController.text;
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      await authService.signInWithEmailAndPassword(email, password);
    } on AuthApiException catch (e) {
      if (e.code == 'email_not_confirmed') {
        await authService.resendSignUpOtp(email);

        if (mounted) {
          await context.push(AppRoutes.authOtp, extra: email);
        }
      } else {
        if (mounted) {
          DevlogToast.show(context, e.message, type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        DevlogToast.show(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void register() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final response = await authService.signUpWithEmailAndPassword(
        email,
        password,
      );

      final identities = response.user?.identities ?? [];
      if (identities.isEmpty) {
        // Email already belongs to an existing (likely OAuth) account.
        if (mounted) {
          DevlogToast.show(
            context,
            'This email is already registered. Try signing in with Google/GitHub, '
            'or use "Set a password" from your profile after signing in.',
            type: ToastType.error,
          );
        }
        return;
      }

      if (!mounted) return;

      await context.push(AppRoutes.authOtp, extra: email);
    } on AuthException catch (e) {
      if (mounted) {
        DevlogToast.show(context, e.message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        DevlogToast.show(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        debugPrint(
          'OAUTH: auth state changed — event: ${data.event}, session: ${data.session != null}',
        );
        if (data.session != null && mounted) {
          debugPrint('OAUTH: mounted=true, calling goToFeed()');
          goToFeed();
        } else {
          debugPrint(
            'OAUTH: session null or widget unmounted — mounted=$mounted',
          );
        }
      },
      onError: (e, stack) {
        debugPrint('OAUTH: auth stream error: $e');
        debugPrint('OAUTH: stack: $stack');
      },
    );

    _emailController.addListener(() => setState(() {}));

    _passwordController.addListener(() {
      setState(() {
        passwordValidation = AuthValidators.passwordRequirements(
          _passwordController.text,
        );
      });
    });

    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() => _showPasswordChecklist = true);
      } else if (passwordValidation.isValid) {
        setState(() => _showPasswordChecklist = false);
      }
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _introController.dispose();
    super.dispose();
  }

  void _switchTab(bool toLogin) {
    if (isLogin == toLogin) return;
    FocusScope.of(context).unfocus();
    setState(() {
      isLogin = toLogin;
      showPassword = false;
      _showPasswordChecklist = false;
      _emailController.clear();
      _passwordController.clear();
      passwordValidation = AuthValidators.passwordRequirements('');
    });
  }

  bool get _canSubmit {
    final emailValid = AuthValidators.email(_emailController.text) == null;
    if (isLogin) {
      return emailValid && _passwordController.text.isNotEmpty;
    }
    return emailValid && passwordValidation.isValid;
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: c.bg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: ThemeToggleButton(
          onToggle: () => context.read<ThemeController>().toggleTheme(),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideIn,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const DevlogBrand(size: 30),
                    const SizedBox(height: 28),
                    AuthCard(
                      colors: c,
                      isDark: isDark,
                      isLogin: isLogin,
                      showPassword: showPassword,
                      showPasswordChecklist: _showPasswordChecklist,
                      canSubmit: _canSubmit && !_isLoading,
                      isLoading: _isLoading, // <-- new
                      passwordValidation: passwordValidation,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      passwordFocusNode: _passwordFocusNode,
                      onSubmit: isLogin ? login : register,
                      onToggleShowPassword: () =>
                          setState(() => showPassword = !showPassword),
                      onSwitchTab: _isLoading
                          ? (_) {}
                          : _switchTab, // block tab-switch mid-submit
                      onGoogleTap: authService.signInWithGoogle,
                      onGithubTap: authService.signInWithGithub,
                      onForgotPassword: () => showForgotPasswordDialog(context),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLogin ? 'New here?' : 'Already have an account?',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                        GestureDetector(
                          onTap: () => _switchTab(!isLogin),
                          child: Text(
                            isLogin ? ' Create an account' : ' Sign in',
                            style: TextStyle(
                              fontSize: 12,
                              color: c.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
