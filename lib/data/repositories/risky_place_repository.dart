import 'package:sqflite_sqlcipher/sqflite.dart';

import '../database/app_database.dart';
import '../models/risky_place.dart';

class RiskyPlaceRepository {
  Future<List<RiskyPlace>> getAll({required String userId}) async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'risky_places',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return maps.map(RiskyPlace.fromMap).toList();
  }

  Future<RiskyPlace?> getById(String id) async {
    final db = await AppDatabase.database;

    final maps = await db.query(
      'risky_places',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return RiskyPlace.fromMap(maps.first);
  }

  Future<void> save(RiskyPlace place) async {
    final db = await AppDatabase.database;

    await db.insert(
      'risky_places',
      place.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.database;

    await db.delete(
      'risky_place_alerts',
      where: 'risky_place_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'risky_place_notification_cooldowns',
      where: 'risky_place_id = ?',
      whereArgs: [id],
    );

    await db.delete(
      'risky_places',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
