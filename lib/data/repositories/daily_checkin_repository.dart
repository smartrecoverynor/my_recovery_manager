import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/utils/app_day.dart';
import '../../data/database/app_database.dart';
import '../models/daily_checkin.dart';

class DailyCheckinRepository {
  Future<void> save(DailyCheckin checkin) async {
    final db = await AppDatabase.database;

    await db.insert('daily_checkins', {
      'id': checkin.id,
      'user_id': checkin.userId,
      'app_date': checkin.appDate.toIso8601String(),
      'mood': checkin.mood,
      'craving': checkin.craving,
      'alcohol_units': checkin.alcoholUnits,
      'journal_text': checkin.journalText,
      'created_at': checkin.createdAt.toIso8601String(),
      'updated_at': checkin.updatedAt.toIso8601String(),
    });
  }

  Future<void> upsert(DailyCheckin checkin) async {
    final db = await AppDatabase.database;

    await db.insert('daily_checkins', {
      'id': checkin.id,
      'user_id': checkin.userId,
      'app_date': checkin.appDate.toIso8601String(),
      'mood': checkin.mood,
      'craving': checkin.craving,
      'alcohol_units': checkin.alcoholUnits,
      'journal_text': checkin.journalText,
      'created_at': checkin.createdAt.toIso8601String(),
      'updated_at': checkin.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<DailyCheckin?> getToday({required String userId}) async {
    final appDate = getAppDate(DateTime.now());

    return getByDate(userId: userId, appDate: appDate);
  }

  Future<DailyCheckin?> getByDate({
    required String userId,
    required DateTime appDate,
  }) async {
    final db = await AppDatabase.database;

    final results = await db.query(
      'daily_checkins',
      where: 'user_id = ? AND app_date = ?',
      whereArgs: [userId, appDate.toIso8601String()],
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return _fromMap(results.first);
  }

  Future<List<DailyCheckin>> getByDateRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await AppDatabase.database;

    final fromAppDate = DateTime(from.year, from.month, from.day);

    final toAppDate = DateTime(to.year, to.month, to.day);

    final results = await db.query(
      'daily_checkins',
      where: '''
        user_id = ?
        AND app_date >= ?
        AND app_date <= ?
      ''',
      whereArgs: [
        userId,
        fromAppDate.toIso8601String(),
        toAppDate.toIso8601String(),
      ],
      orderBy: 'app_date ASC',
    );

    return results.map(_fromMap).toList();
  }

  DailyCheckin _fromMap(Map<String, Object?> data) {
    return DailyCheckin(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      appDate: DateTime.parse(data['app_date'] as String),
      mood: data['mood'] as int?,
      craving: data['craving'] as int?,
      alcoholUnits: data['alcohol_units'] as int,
      journalText: data['journal_text'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }
}
