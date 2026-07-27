import 'package:blog_app/core/router/app_router.dart';
import 'package:blog_app/core/services/post_sync_service.dart';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/theme/theme_controller.dart';
import 'package:blog_app/features/auth/screens/controllers/auth_controller.dart';
import 'package:blog_app/features/notifications/providers/notifications_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment('SUPABASE_PUBKEY');

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseKey);

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      appRouter.go(AppRoutes.resetPassword);
    }
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => PostSyncService()),
        ChangeNotifierProvider(
          create: (_) => NotificationsProvider()
            ..loadInitial()
            ..subscribeToRealtime(),
        ),
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
