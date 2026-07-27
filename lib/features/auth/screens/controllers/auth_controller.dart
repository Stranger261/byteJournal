import 'package:blog_app/features/profile/data/profile_service.dart';
import 'package:blog_app/features/auth/data/user_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  final _profileService = ProfileService();
  UserModel? profile;

  late final _sub;

  AuthController() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (data.session != null) {
        await _loadProfile();
      } else {
        profile = null;
      }
      notifyListeners();
    });
  }
  User? get currentUser => Supabase.instance.client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<void> _loadProfile() async {
    if (currentUser == null) return;
    profile = await _profileService.getProfile(currentUser!.id);
  }

  Future<void> refreshProfile() async {
    await _loadProfile();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
