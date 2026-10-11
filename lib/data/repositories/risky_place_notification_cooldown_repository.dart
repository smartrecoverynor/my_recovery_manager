import 'package:sqflite_sqlcipher/sqflite.dart';

import '../database/app_database.dart';

class RiskyPlaceNotificationCooldownRepository {
  Future<DateTime?> getLastNotifiedAt(String riskyPlaceId) async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'risky_place_notification_cooldowns',
      columns: ['last_notified_at'],
      where: 'risky_place_id = ?',
      whereArgs: [riskyPlaceId],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return DateTime.parse(maps.first['last_notified_at'] as String);
  }

  Future<void> saveLastNotifiedAt(
      String riskyPlaceId,
      DateTime timestamp,
      ) async {
    final db = await AppDatabase.database;

    await db.insert(
      'risky_place_notification_cooldowns',
      {
        'id': riskyPlaceId,
        'risky_place_id': riskyPlaceId,
        'last_notified_at': timestamp.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String riskyPlaceId) async {
    final db = await AppDatabase.database;

    await db.delete(
      'risky_place_notification_cooldowns',
      where: 'risky_place_id = ?',
      whereArgs: [riskyPlaceId],
    );
  }
}