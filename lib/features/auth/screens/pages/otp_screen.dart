import 'dart:async';

import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/toast.dart';
import 'package:blog_app/core/widgets/loading_submit_button.dart';
import 'package:blog_app/features/auth/data/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _authService = AuthService();

  bool _verifying = false;
  bool _resending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  bool get _canVerify => _otpController.text.trim().length == 6;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() => setState(() {}));
    _startCooldown();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _verify() async {
    if (_verifying || !_canVerify) return;

    setState(() => _verifying = true);
    try {
      await _authService.verifySignupOtp(
        widget.email,
        _otpController.text.trim(),
      );

      if (mounted) {
        context.go(AppRoutes.feed);
      }
    } on AuthException catch (e) {
      if (mounted) {
        DevlogToast.show(context, e.message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        DevlogToast.show(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _resendCooldown > 0) return;

    setState(() => _resending = true);
    try {
      await _authService.resendSignUpOtp(widget.email);
      if (mounted) {
        DevlogToast.show(
          context,
          'Code resent. Check your inbox.',
          type: ToastType.success,
        );
        _startCooldown();
      }
    } on AuthException catch (e) {
      if (mounted) {
        DevlogToast.show(context, e.message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        DevlogToast.show(context, 'Error: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: const Text('Verify your email'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.mark_email_read_outlined, size: 42, color: c.accent),
                const SizedBox(height: 16),
                Text(
                  'Enter the 6-digit code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent it to ${widget.email}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: c.secondary),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _otpController,
                  enabled: !_verifying,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  autofocus: true,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    fontSize: 24,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    hintText: '000000',
                  ),
                  onSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 20),
                LoadingSubmitButton(
                  enabled: _canVerify,
                  isLoading: _verifying,
                  label: 'Verify',
                  loadingLabel: 'Verifying…',
                  onTap: _verify,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: (_resendCooldown > 0 || _resending)
                        ? null
                        : _resend,
                    child: Text(
                      _resending
                          ? 'Resending…'
                          : _resendCooldown > 0
                          ? 'Resend code in ${_resendCooldown}s'
                          : 'Resend code',
                      style: TextStyle(
                        color: (_resendCooldown > 0 || _resending)
                            ? c.muted
                            : c.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
