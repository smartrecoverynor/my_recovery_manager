import '../../core/utils/app_day.dart';
import '../database/app_database.dart';
import '../models/user_goal.dart';

class UserGoalRepository {
  Future<UserGoal?> getActive({required String userId}) async {
    final appDate = getAppDate(DateTime.now());

    return getForDate(userId: userId, appDate: appDate);
  }

  Future<UserGoal?> getForDate({
    required String userId,
    required DateTime appDate,
  }) async {
    final db = await AppDatabase.database;

    final results = await db.query(
      'user_goals',
      where: '''
        user_id = ?
        AND valid_from <= ?
        AND (valid_to IS NULL OR valid_to >= ?)
      ''',
      whereArgs: [userId, appDate.toIso8601String(), appDate.toIso8601String()],
      orderBy: 'valid_from DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return _fromMap(results.first);
  }

  Future<List<UserGoal>> getHistory({required String userId}) async {
    final db = await AppDatabase.database;

    final results = await db.query(
      'user_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'valid_from ASC',
    );

    return results.map(_fromMap).toList();
  }

  Future<void> setActiveGoal(UserGoal goal) async {
    final db = await AppDatabase.database;

    final appDate = goal.validFrom;

    await db.transaction((txn) async {
      final activeResults = await txn.query(
        'user_goals',
        where: '''
          user_id = ?
          AND valid_from <= ?
          AND (valid_to IS NULL OR valid_to >= ?)
        ''',
        whereArgs: [
          goal.userId,
          appDate.toIso8601String(),
          appDate.toIso8601String(),
        ],
        orderBy: 'valid_from DESC',
        limit: 1,
      );

      if (activeResults.isNotEmpty) {
        final current = _fromMap(activeResults.first);

        // Dersom brukeren endrer målet flere ganger samme app-dag,
        // oppdaterer vi dagens rad i stedet for å lage en meningsløs
        // null-dagers historikkperiode.
        if (_isSameDate(current.validFrom, appDate)) {
          await txn.update(
            'user_goals',
            {
              'goal_type': goal.goalTypeValue,
              'weekly_limit': goal.weeklyLimit,
              'daily_limit': goal.dailyLimit,
              'alcohol_free_days': goal.alcoholFreeDays,
              'updated_at': DateTime.now().toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [current.id],
          );

          return;
        }

        final previousDay = appDate.subtract(const Duration(days: 1));

        await txn.update(
          'user_goals',
          {
            'valid_to': previousDay.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [current.id],
        );
      }

      await txn.insert('user_goals', {
        'id': goal.id,
        'user_id': goal.userId,
        'goal_type': goal.goalTypeValue,
        'weekly_limit': goal.weeklyLimit,
        'daily_limit': goal.dailyLimit,
        'alcohol_free_days': goal.alcoholFreeDays,
        'valid_from': goal.validFrom.toIso8601String(),
        'valid_to': goal.validTo?.toIso8601String(),
        'created_at': goal.createdAt.toIso8601String(),
        'updated_at': goal.updatedAt.toIso8601String(),
      });
    });
  }

  Future<void> clearActiveGoal({required String userId}) async {
    final db = await AppDatabase.database;

    final appDate = getAppDate(DateTime.now());

    await db.transaction((txn) async {
      final results = await txn.query(
        'user_goals',
        where: '''
          user_id = ?
          AND valid_from <= ?
          AND (valid_to IS NULL OR valid_to >= ?)
        ''',
        whereArgs: [
          userId,
          appDate.toIso8601String(),
          appDate.toIso8601String(),
        ],
        orderBy: 'valid_from DESC',
        limit: 1,
      );

      if (results.isEmpty) {
        return;
      }

      final current = _fromMap(results.first);

      // Hvis målet ble opprettet i dag og brukeren avbryter samme dag,
      // kan vi fjerne raden helt.
      if (_isSameDate(current.validFrom, appDate)) {
        await txn.delete(
          'user_goals',
          where: 'id = ?',
          whereArgs: [current.id],
        );
        return;
      }

      final previousDay = appDate.subtract(const Duration(days: 1));

      await txn.update(
        'user_goals',
        {
          'valid_to': previousDay.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [current.id],
      );
    });
  }

  UserGoal _fromMap(Map<String, Object?> data) {
    return UserGoal(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      goalType: UserGoal.goalTypeFromValue(data['goal_type'] as String),
      weeklyLimit: data['weekly_limit'] as int?,
      dailyLimit: data['daily_limit'] as int?,
      alcoholFreeDays: data['alcohol_free_days'] as int?,
      validFrom: DateTime.parse(data['valid_from'] as String),
      validTo: data['valid_to'] == null
          ? null
          : DateTime.parse(data['valid_to'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
