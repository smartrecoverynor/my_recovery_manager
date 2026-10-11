import 'package:sqflite_sqlcipher/sqflite.dart';

import '../database/app_database.dart';

class RiskyPlaceSettingsRepository {
  static const String _userId = 'local-user';
  static const String _settingsId = 'local-settings';

  Future<String?> getGlobalInstruction() async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'risky_place_settings',
      where: 'user_id = ?',
      whereArgs: [_userId],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return maps.first['global_instruction'] as String?;
  }

  Future<void> saveGlobalInstruction(String? instruction) async {
    final db = await AppDatabase.database;

    final now = DateTime.now().toIso8601String();

    await db.insert(
      'risky_place_settings',
      {
        'id': _settingsId,
        'user_id': _userId,
        'global_instruction': instruction,
        'created_at': now,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}