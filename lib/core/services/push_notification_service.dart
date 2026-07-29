import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('PUSH: background message: ${message.messageId}');
}

class PushNotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'high_importance_channel';
  static const _channelName = 'Important Notifications';

  Future<void> initialize() async {
    await _initLocalNotifications();

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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('PUSH: foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('PUSH: opened from background: ${message.data}');
      // TODO: navigate to the relevant post using message.data['post_id']
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
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