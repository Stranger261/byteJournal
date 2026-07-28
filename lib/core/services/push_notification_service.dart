import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Must be a TOP-LEVEL function (outside the class) — Firebase calls this
// in a separate isolate when the app is fully terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('PUSH: background message: ${message.messageId}');
}

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

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('PUSH: token refreshed');
      _saveToken(newToken);
    });

    // Foreground — app open, FCM won't auto-show a system tray notification,
    // so this is where you'd trigger a local notification if you want one
    // visible while the app is in use.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('PUSH: foreground message: ${message.notification?.title}');
      // TODO: show a local notification manually (flutter_local_notifications)
    });

    // User tapped a notification while app was backgrounded, bringing it
    // to foreground.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('PUSH: opened from background: ${message.data}');
      // TODO: navigate to the relevant post using message.data['post_id']
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
