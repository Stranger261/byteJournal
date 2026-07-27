import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Web build's deployed URL — update if your Vercel URL changes
  // (e.g. after setting up a custom domain).
  static const String _webRedirectBase = 'https://web-ruby-one-95.vercel.app';

  static const String _mobileLoginCallback =
      'io.supabase.devlog://login-callback';
  static const String _mobileResetCallback =
      'io.supabase.devlog://reset-callback';

  String get _loginRedirect => kIsWeb ? _webRedirectBase : _mobileLoginCallback;

  String get _resetRedirect =>
      kIsWeb ? '$_webRedirectBase/reset-password' : _mobileResetCallback;

  // sign in with email and pass
  Future<AuthResponse> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // sign up email and pass
  Future<AuthResponse> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> verifySignupOtp(String email, String token) async {
    return await _supabase.auth.verifyOTP(
      type: OtpType.signup,
      email: email,
      token: token,
    );
  }

  Future<void> resendSignUpOtp(String email) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email);
  }

  // sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;

    return user?.email;
  }

  Future<void> signInWithGoogle() async {
    debugPrint('OAUTH: signInWithGoogle called, redirectTo=$_loginRedirect');
    try {
      final result = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _loginRedirect,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      debugPrint('OAUTH: signInWithOAuth returned: $result');
    } catch (e, stack) {
      debugPrint('OAUTH: signInWithOAuth threw: $e');
      debugPrint('OAUTH: stack: $stack');
      rethrow;
    }
  }

  Future<void> signInWithGithub() async {
    debugPrint('OAUTH: signInWithGithub called, redirectTo=$_loginRedirect');
    try {
      final result = await _supabase.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: _loginRedirect,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      debugPrint('OAUTH: signInWithGithub returned: $result');
    } catch (e, stack) {
      debugPrint('OAUTH: signInWithGithub threw: $e');
      debugPrint('OAUTH: stack: $stack');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: _resetRedirect,
    );
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
