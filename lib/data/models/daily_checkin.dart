import '../../core/utils/app_day.dart';

class DailyCheckin {
  final String id;
  final String userId;
  final DateTime appDate;
  final int? mood;
  final int? craving;
  final int alcoholUnits;
  final String? journalText;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DailyCheckin({
    required this.id,
    required this.userId,
    required this.appDate,
    this.mood,
    this.craving,
    required this.alcoholUnits,
    this.journalText,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DailyCheckin.create({
    required String id,
    required String userId,
    required DateTime dateTime,
    int? mood,
    int? craving,
    int alcoholUnits = 0,
    String? journalText,
  }) {
    final now = DateTime.now();

    return DailyCheckin(
      id: id,
      userId: userId,
      appDate: getAppDate(dateTime),
      mood: mood,
      craving: craving,
      alcoholUnits: alcoholUnits,
      journalText: journalText,
      createdAt: now,
      updatedAt: now,
    );
  }
}
