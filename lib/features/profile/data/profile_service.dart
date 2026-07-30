import 'dart:typed_data';

import 'package:blog_app/features/auth/data/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  final _supabase = Supabase.instance.client;

  Future<UserModel> getProfile(String userId) async {
    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
    return UserModel.fromMap(data);
  }

  Future<void> updateName(String userId, String name) async {
    await _supabase
        .from('profiles')
        .update({'name': name, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }

  Future<String> uploadAvatar(
    String userId,
    Uint8List bytes,
    String ext,
  ) async {
    final path = '$userId/avatar.$ext';

    final existing = await _supabase.storage.from('avatars').list(path: userId);
    final oldFiles = existing
        .where((f) => f.name.startsWith('avatar.'))
        .map((f) => '$userId/${f.name}')
        .toList();
    if (oldFiles.isNotEmpty) {
      await _supabase.storage.from('avatars').remove(oldFiles);
    }

    await _supabase.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final baseUrl = _supabase.storage.from('avatars').getPublicUrl(path);
    final url = '$baseUrl?updated=${DateTime.now().millisecondsSinceEpoch}';

    await _supabase
        .from('profiles')
        .update({
          'avatar_url': url,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);

    return url;
  }

  Future<void> deleteAvatar(String userId) async {
    final files = await _supabase.storage.from('avatars').list(path: userId);
    final avatarFiles = files
        .where((f) => f.name.startsWith('avatar.'))
        .map((f) => '$userId/${f.name}')
        .toList();

    if (avatarFiles.isNotEmpty) {
      await _supabase.storage.from('avatars').remove(avatarFiles);
    }

    await _supabase
        .from('profiles')
        .update({
          'avatar_url': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  Future<void> changePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> setPasswordForOAuthAccount(String newPassword) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}
