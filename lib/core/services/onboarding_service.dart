import 'dart:io';

import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class OnboardingService {
  OnboardingService._();

  static const String _completedKey = 'onboarding_completed';

  static Future<String> resolveInitialLocation() async {
    final preferences = await SharedPreferences.getInstance();
    final completed = preferences.getBool(_completedKey);

    if (completed != null) {
      return completed ? '/dashboard' : '/profile-setup';
    }

    // Sjekk databasen før andre oppstartstjenester kan opprette den.
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'my_recovery_manager.db');
    final databaseExists = await File(path).exists();

    // En eksisterende database betyr at appen allerede har vært i bruk.
    await preferences.setBool(_completedKey, databaseExists);

    return databaseExists ? '/dashboard' : '/profile-setup';
  }

  static Future<void> markCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_completedKey, true);
  }

  static Future<void> reset() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_completedKey);
  }
}
