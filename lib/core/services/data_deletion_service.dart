import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import 'notification_service.dart';
import 'risky_place_region_service.dart';

class DataDeletionService {
  DataDeletionService._();

  static final DataDeletionService instance = DataDeletionService._();

  static const List<String> _sharedPreferencesKeys = [
    'panic_button_selected_actions',
    'panic_button_selected_image_path',
    'panic_button_consequences',
    'support_cards_deleted',
    'support_cards_custom',
    'support_cards_selected',
    'support_cards_count',
    'permissive_thoughts_custom',
    'permissive_thoughts_responses',
    'panic_button_call_friend_contact_id',
    'onboarding_completed',
  ];

  Future<void> deleteAllUserData() async {
    Object? firstError;

    try {
      await RiskyPlaceRegionService.instance.stopAllMonitoring();
    } catch (e) {
      firstError ??= e;
    }

    try {
      await NotificationService.instance.cancelAll();
    } catch (e) {
      firstError ??= e;
    }

    try {
      await _deletePanicButtonImage();
    } catch (e) {
      firstError ??= e;
    }

    try {
      await _deleteUserPreferences();
    } catch (e) {
      firstError ??= e;
    }

    try {
      await AppDatabase.deleteDatabase();
    } catch (e) {
      firstError ??= e;
    }

    if (firstError != null) {
      throw StateError(
        'Kunne ikke fullføre sletting av alle lokale brukerdata.',
      );
    }
  }

  Future<void> _deletePanicButtonImage() async {
    final preferences = await SharedPreferences.getInstance();

    final imagePath = preferences.getString('panic_button_selected_image_path');

    if (imagePath == null || imagePath.trim().isEmpty) {
      return;
    }

    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _deleteUserPreferences() async {
    final preferences = await SharedPreferences.getInstance();

    for (final key in _sharedPreferencesKeys) {
      await preferences.remove(key);
    }
  }
}
