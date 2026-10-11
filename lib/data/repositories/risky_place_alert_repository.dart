import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/risky_place_alert.dart';

class RiskyPlaceAlertRepository {
  Future<List<RiskyPlaceAlert>> getForPlace(String riskyPlaceId) async {
    final db = await AppDatabase.database;

    final rows = await db.query(
      'risky_place_alerts',
      where: 'risky_place_id = ?',
      whereArgs: [riskyPlaceId],
      orderBy: 'from_time ASC',
    );

    return rows.map(RiskyPlaceAlert.fromMap).toList();
  }

  Future<void> save(RiskyPlaceAlert alert) async {
    final db = await AppDatabase.database;

    await db.insert(
      'risky_place_alerts',
      alert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.database;

    await db.delete('risky_place_alerts', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteForPlace(String riskyPlaceId) async {
    final db = await AppDatabase.database;

    await db.delete(
      'risky_place_alerts',
      where: 'risky_place_id = ?',
      whereArgs: [riskyPlaceId],
    );
  }

  String createId() {
    return const Uuid().v4();
  }
}
