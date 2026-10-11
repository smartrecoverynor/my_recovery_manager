import 'package:sqflite_sqlcipher/sqflite.dart';

import '../database/app_database.dart';
import '../models/situation_experience.dart';

class SituationExperienceRepository {
  Future<void> save(SituationExperience experience) async {
    final db = await AppDatabase.database;

    await db.insert('situation_experiences', {
      'id': experience.id,
      'situation_id': experience.situationId,
      'user_id': experience.userId,
      'what_worked': experience.whatWorked,
      'what_did_not_work': experience.whatDidNotWork,
      'learning': experience.learning,
      'created_at': experience.createdAt.toIso8601String(),
      'updated_at': experience.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SituationExperience>> getForSituation({
    required String situationId,
    required String userId,
  }) async {
    final db = await AppDatabase.database;

    final results = await db.query(
      'situation_experiences',
      where: 'situation_id = ? AND user_id = ?',
      whereArgs: [situationId, userId],
      orderBy: 'created_at DESC',
    );

    return results.map(_fromMap).toList();
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.database;

    await db.delete('situation_experiences', where: 'id = ?', whereArgs: [id]);
  }

  SituationExperience _fromMap(Map<String, dynamic> data) {
    return SituationExperience(
      id: data['id'] as String,
      situationId: data['situation_id'] as String,
      userId: data['user_id'] as String,
      whatWorked: data['what_worked'] as String?,
      whatDidNotWork: data['what_did_not_work'] as String?,
      learning: data['learning'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }
}
