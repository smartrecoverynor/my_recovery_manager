import 'package:sqflite_sqlcipher/sqflite.dart';

import '../database/app_database.dart';
import '../models/reminder.dart';

class ReminderRepository {
  Future<void> save(Reminder reminder) async {
    final db = await AppDatabase.database;

    await db.insert('reminders', {
      'id': reminder.id,
      'plan_id': reminder.planId,
      'type': reminder.type,
      'offset_minutes': reminder.offsetMinutes,
      'scheduled_at': reminder.scheduledAt?.toIso8601String(),
      'message': reminder.message,
      'created_at': reminder.createdAt.toIso8601String(),
      'updated_at': reminder.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Reminder>> getForPlan(String planId) async {
    final db = await AppDatabase.database;

    final results = await db.query(
      'reminders',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'scheduled_at ASC',
    );

    return results.map(_fromMap).toList();
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.database;

    await db.delete('reminders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteForPlan(String planId) async {
    final db = await AppDatabase.database;

    await db.delete('reminders', where: 'plan_id = ?', whereArgs: [planId]);
  }

  Reminder _fromMap(Map<String, dynamic> data) {
    return Reminder(
      id: data['id'] as String,
      planId: data['plan_id'] as String,
      type: data['type'] as String,
      offsetMinutes: data['offset_minutes'] as int?,
      scheduledAt: data['scheduled_at'] == null
          ? null
          : DateTime.parse(data['scheduled_at'] as String),
      message: data['message'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }
}
