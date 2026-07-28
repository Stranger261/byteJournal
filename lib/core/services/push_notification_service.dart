import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('PUSH: permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('PUSH: user denied notification permission');
      return;
    }

    await _registerToken();

    // FCM tokens can rotate — listen for refresh and re-save.
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('PUSH: token refreshed');
      _saveToken(newToken);
    });
  }

  Future<void> _registerToken() async {
    final token = await _messaging.getToken();
    if (token == null) {
      debugPrint('PUSH: failed to get FCM token');
      return;
    }
    debugPrint('PUSH: got FCM token: $token');
    await _saveToken(token);
  }

  Future<void> _saveToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('PUSH: no logged in user, skipping token save');
      return;
    }

    try {
      await _supabase.from('device_tokens').upsert({
        'user_id': userId,
        'fcm_token': token,
      }, onConflict: 'fcm_token');
      debugPrint('PUSH: token saved to Supabase');
    } catch (e) {
      debugPrint('PUSH: failed to save token: $e');
    }
  }

  /// Call this on logout to stop associating this device with the user.
  Future<void> removeCurrentToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;

    try {
      await _supabase.from('device_tokens').delete().eq('fcm_token', token);
      debugPrint('PUSH: token removed on logout');
    } catch (e) {
      debugPrint('PUSH: failed to remove token: $e');
    }
  }
}
