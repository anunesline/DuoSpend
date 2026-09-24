import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OrbitAppearanceController extends ChangeNotifier {
  OrbitAppearanceController._();

  static final OrbitAppearanceController instance = OrbitAppearanceController._();

  ThemeMode _themeMode = ThemeMode.dark;
  ThemeMode get themeMode => _themeMode;

  Future<void> loadForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final value = snapshot.data()?['appearance']?.toString();
    _setLocal(_fromValue(value));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _setLocal(mode);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'appearance': _toValue(mode)},
      SetOptions(merge: true),
    );
  }

  void _setLocal(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
  }

  ThemeMode _fromValue(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _toValue(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}
