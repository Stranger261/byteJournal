import 'package:blog_app/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<bool> requireAuth(BuildContext context) async {
  final isLoggedIn = Supabase.instance.client.auth.currentUser != null;
  if (isLoggedIn) return true;

  await context.push(AppRoutes.auth);

  return Supabase.instance.client.auth.currentUser != null;
}
