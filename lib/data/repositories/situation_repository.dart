import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../data/database/app_database.dart';
import '../../features/prevention/situation.dart';

class SituationRepository {
  Future<void> save(Situation situation) async {
    final db = await AppDatabase.database;

    await db.insert('situations', {
      'id': situation.id,
      'user_id': situation.userId,
      'text': situation.text,
      'category': situation.category.name,
      'created_at': situation.createdAt.toIso8601String(),
      'updated_at': situation.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Situation>> getAll({required String userId}) async {
    final db = await AppDatabase.database;

    final results = await db.query(
      'situations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    return results.map(_fromMap).toList();
  }

  Future<void> delete(String id) async {
    final db = await AppDatabase.database;

    await db.delete('situations', where: 'id = ?', whereArgs: [id]);
  }

  Situation _fromMap(Map<String, dynamic> data) {
    return Situation(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      text: data['text'] as String,
      category: SituationCategory.values.firstWhere(
        (category) => category.name == data['category'],
      ),
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }
}
