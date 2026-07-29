import 'package:blog_app/core/router/app_router.dart';
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

    // Foreground — app open, FCM won't auto-show a system tray notification,
    // so we show a local one manually. Tapping it triggers
    // onDidReceiveNotificationResponse (wired in _initLocalNotifications).
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('PUSH: foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // User tapped the OS notification while app was backgrounded/terminated,
    // bringing it to foreground.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('PUSH: opened from background: ${message.data}');
      _navigateFromMessage(message.data);
    });

    // If the app was fully terminated and got opened by tapping a push,
    // this returns that initial message once, on cold start.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('PUSH: opened from terminated: ${initialMessage.data}');
      _navigateFromMessage(initialMessage.data);
    }
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        debugPrint('PUSH: local notification tapped, payload: $payload');
        if (payload != null && payload.isNotEmpty) {
          _navigateToPost(payload);
        }
      },
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final postId = message.data['post_id'];

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      payload: postId, // carried through to onDidReceiveNotificationResponse
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  void _navigateFromMessage(Map<String, dynamic> data) {
    final postId = data['post_id'] as String?;
    if (postId != null && postId.isNotEmpty) {
      _navigateToPost(postId);
    }
  }

  void _navigateToPost(String postId) {
    appRouter.push(AppRoutes.postDetailPath(postId));
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
