import 'dart:io';

import 'package:blog_app/features/profile/data/profile_service.dart';
import 'package:blog_app/features/auth/data/user_model.dart';
import 'package:flutter/material.dart';

class ProfileProvider extends ChangeNotifier {
  final _profileService = ProfileService();

  UserModel? profile;
  bool isLoading = false;
  bool isSaving = false;
  String? error;

  Future<void> load(String userId) async {
    isLoading = true;
    notifyListeners();
    try {
      profile = await _profileService.getProfile(userId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateName(String userId, String name) async {
    isSaving = true;
    notifyListeners();
    try {
      await _profileService.updateName(userId, name);
      await load(userId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> updateAvatar(String userId, File file) async {
    isSaving = true;
    notifyListeners();
    try {
      await _profileService.uploadAvatar(userId, file);
      await load(userId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> removeAvatar(String userId) async {
    isSaving = true;
    notifyListeners();
    try {
      await _profileService.deleteAvatar(userId);
      await load(userId);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword(String newPassword) async {
    isSaving = true;
    notifyListeners();
    try {
      await _profileService.changePassword(newPassword);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
}
