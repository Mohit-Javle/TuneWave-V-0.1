// lib/services/auth_service.dart
import 'dart:async';
import 'package:clone_mp/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  // Singleton pattern for easy access
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  final StreamController<UserModel?> _userController =
      StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get userStream => _userController.stream;

  // This method will run on app start to check for a saved session
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName');
    final userEmail = prefs.getString('userEmail');
    final userImageUrl = prefs.getString('userImageUrl');

    if (userName != null && userEmail != null) {
      _currentUser = UserModel(
        name: userName,
        email: userEmail,
        imageUrl: userImageUrl,
      );
      _userController.add(_currentUser);
      notifyListeners();
    }
  }

  // Updated login method to save user data
  Future<void> login(String name, String email) async {
    _currentUser = UserModel(name: name, email: email);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    await prefs.setString('userEmail', email);

    _userController.add(_currentUser);
    notifyListeners();
  }

  // Updated logout method to clear user data
  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userImageUrl');

    _userController.add(null);
    notifyListeners();
  }

  // Update profile and save changes
  Future<void> updateUserProfile({
    required String newName,
    String? newImageUrl,
  }) async {
    if (_currentUser != null) {
      _currentUser = UserModel(
        name: newName,
        email: _currentUser!.email,
        imageUrl: newImageUrl ?? _currentUser!.imageUrl,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', _currentUser!.name);
      if (_currentUser!.imageUrl != null) {
        await prefs.setString('userImageUrl', _currentUser!.imageUrl!);
      }
      _userController.add(_currentUser);
      notifyListeners();
    }
  }
}
