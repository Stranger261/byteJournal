import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/services/post_realtime_service.dart';
import 'package:blog_app/core/services/post_sync_service.dart';
import 'package:blog_app/core/services/push_notification_service.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/theme/theme_controller.dart';
import 'package:blog_app/features/auth/screens/controllers/auth_controller.dart';
import 'package:blog_app/features/notifications/providers/notifications_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_PUBKEY');

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  final postSyncService = PostSyncService();
  final notificationsProvider = NotificationsProvider();
  final pushNotificationService = PushNotificationService();
  final postRealtimeService = PostRealtimeService(syncService: postSyncService);

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    switch (data.event) {
      case AuthChangeEvent.passwordRecovery:
        appRouter.go(AppRoutes.resetPassword);
        break;
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
        notificationsProvider
          ..loadInitial()
          ..subscribeToRealtime();
        pushNotificationService.initialize();
        postRealtimeService.start();
        break;
      case AuthChangeEvent.signedOut:
        notificationsProvider.unsubscribeFromRealtime();
        notificationsProvider.clear();
        pushNotificationService.removeCurrentToken();
        postRealtimeService.stop();
        break;
      default:
        break;
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider.value(value: postSyncService),
        ChangeNotifierProvider.value(value: notificationsProvider),
      ],
      child: const ByteJorunalApp(),
    ),
  );
}

final supabase = Supabase.instance.client;

class ByteJorunalApp extends StatelessWidget {
  const ByteJorunalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp.router(
      title: 'byteJournal',
      debugShowCheckedModeBanner: false,

      themeMode: themeController.mode,

      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeInOut,

      theme: buildDevlogTheme(DevlogColors.light, Brightness.light),

      darkTheme: buildDevlogTheme(DevlogColors.dark, Brightness.dark),
      routerConfig: appRouter,
    );
  }
}
