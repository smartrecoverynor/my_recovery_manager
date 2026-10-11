enum UserGoalType { abstinence, moderation }

class UserGoal {
  final String id;
  final String userId;
  final UserGoalType goalType;
  final int? weeklyLimit;
  final int? dailyLimit;
  final int? alcoholFreeDays;
  final DateTime validFrom;
  final DateTime? validTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    this.weeklyLimit,
    this.dailyLimit,
    this.alcoholFreeDays,
    required this.validFrom,
    this.validTo,
    required this.createdAt,
    required this.updatedAt,
  });

  String get goalTypeValue {
    switch (goalType) {
      case UserGoalType.abstinence:
        return 'abstinence';
      case UserGoalType.moderation:
        return 'moderation';
    }
  }

  factory UserGoal.create({
    required String id,
    required String userId,
    required UserGoalType goalType,
    int? weeklyLimit,
    int? dailyLimit,
    int? alcoholFreeDays,
    required DateTime validFrom,
  }) {
    final now = DateTime.now();

    return UserGoal(
      id: id,
      userId: userId,
      goalType: goalType,
      weeklyLimit: weeklyLimit,
      dailyLimit: dailyLimit,
      alcoholFreeDays: alcoholFreeDays,
      validFrom: validFrom,
      validTo: null,
      createdAt: now,
      updatedAt: now,
    );
  }

  static UserGoalType goalTypeFromValue(String value) {
    switch (value) {
      case 'abstinence':
        return UserGoalType.abstinence;
      case 'moderation':
        return UserGoalType.moderation;
      default:
        throw ArgumentError('Ukjent måltype: $value');
    }
  }
}
