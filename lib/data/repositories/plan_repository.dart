import 'package:sqflite_sqlcipher/sqflite.dart';

import '../database/app_database.dart';
import '../models/plan.dart';

class PlanRepository {
  Future<void> save(Plan plan) async {
    final db = await AppDatabase.database;

    await db.insert('plans', {
      'id': plan.id,
      'user_id': plan.userId,
      'situation_text': plan.situationText,
      'category': plan.category,
      'planned_date': plan.plannedDate.toIso8601String(),
      'planned_time': plan.plannedTime,
      'repeat_type': plan.repeat,
      'repeat_count': plan.repeatCount,
      'repeat_until': plan.repeatUntil?.toIso8601String(),
      'note': plan.note,
      'created_at': plan.createdAt.toIso8601String(),
      'updated_at': plan.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Plan>> getAll({required String userId}) async {
    final db = await AppDatabase.database;

    final results = await db.query(
      'plans',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'planned_date ASC, planned_time ASC',
    );

    return results.map(_fromMap).toList();
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.database;

    await db.delete('plans', where: 'id = ?', whereArgs: [id]);
  }

  Plan _fromMap(Map<String, dynamic> data) {
    return Plan(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      situationText: data['situation_text'] as String,
      category: data['category'] as String,
      plannedDate: DateTime.parse(data['planned_date'] as String),
      plannedTime: data['planned_time'] as String?,
      repeat: data['repeat_type'] as String,
      repeatCount: data['repeat_count'] as int?,
      repeatUntil: data['repeat_until'] == null
          ? null
          : DateTime.parse(data['repeat_until'] as String),
      note: data['note'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }
}
