import '../../data/models/daily_checkin.dart';
import '../../data/repositories/daily_checkin_repository.dart';
import '../utils/app_day.dart';

enum StatisticsPeriod { sevenDays, thirtyDays, threeMonths, month, custom }

class DailyAlcoholStatistic {
  final DateTime date;
  final int units;

  const DailyAlcoholStatistic({required this.date, required this.units});
}

class AlcoholStatistics {
  final int totalUnits;
  final int drinkingDays;
  final int registeredDays;
  final double averageUnitsOnDrinkingDays;
  final int highestUnits;
  final List<DailyAlcoholStatistic> dailyData;

  const AlcoholStatistics({
    required this.totalUnits,
    required this.drinkingDays,
    required this.registeredDays,
    required this.averageUnitsOnDrinkingDays,
    required this.highestUnits,
    required this.dailyData,
  });
}

class CravingStatistics {
  final int highestCraving;
  final int daysWithCraving;
  final int mostCommonScore;
  final int registeredDays;

  const CravingStatistics({
    required this.highestCraving,
    required this.daysWithCraving,
    required this.mostCommonScore,
    required this.registeredDays,
  });
}

class MoodStatistics {
  final Map<int, int> scoreCounts;
  final int registeredDays;

  const MoodStatistics({
    required this.scoreCounts,
    required this.registeredDays,
  });
}

class StatisticsService {
  final DailyCheckinRepository _checkinRepository;

  StatisticsService({DailyCheckinRepository? checkinRepository})
    : _checkinRepository = checkinRepository ?? DailyCheckinRepository();

  Future<AlcoholStatistics> getAlcoholStatistics({
    required String userId,
    required StatisticsPeriod period,
    DateTime? endDate,
    DateTime? startDate,
  }) async {
    final range = _calculateRange(
      period: period,
      endDate: endDate,
      startDate: startDate,
    );
    final checkins = await _getCheckins(userId, range.$1, range.$2);
    return _calculateAlcoholStatistics(checkins);
  }

  Future<CravingStatistics> getCravingStatistics({
    required String userId,
    required StatisticsPeriod period,
    DateTime? endDate,
    DateTime? startDate,
  }) async {
    final range = _calculateRange(
      period: period,
      endDate: endDate,
      startDate: startDate,
    );
    final checkins = await _getCheckins(userId, range.$1, range.$2);
    return _calculateCravingStatistics(checkins);
  }

  Future<MoodStatistics> getMoodStatistics({
    required String userId,
    required StatisticsPeriod period,
    DateTime? endDate,
    DateTime? startDate,
  }) async {
    final range = _calculateRange(
      period: period,
      endDate: endDate,
      startDate: startDate,
    );
    final checkins = await _getCheckins(userId, range.$1, range.$2);
    return _calculateMoodStatistics(checkins);
  }

  Future<List<DailyCheckin>> _getCheckins(
    String userId,
    DateTime from,
    DateTime to,
  ) {
    return _checkinRepository.getByDateRange(
      userId: userId,
      from: from,
      to: to,
    );
  }

  (DateTime, DateTime) _calculateRange({
    required StatisticsPeriod period,
    DateTime? endDate,
    DateTime? startDate,
  }) {
    if (period == StatisticsPeriod.custom) {
      if (startDate == null || endDate == null) {
        throw ArgumentError(
          'Egendefinert statistikk krever både startDate og endDate.',
        );
      }

      final start = _dateOnly(startDate);
      final end = _dateOnly(endDate);

      if (end.isBefore(start)) {
        throw ArgumentError('Sluttdato kan ikke være før startdato.');
      }

      return (start, end);
    }

    final end = _dateOnly(endDate ?? getAppDate(DateTime.now()));

    return (
      _calculateStartDate(endDate: end, period: period),
      _calculateEndDate(endDate: end, period: period),
    );
  }

  DateTime _calculateStartDate({
    required DateTime endDate,
    required StatisticsPeriod period,
  }) {
    switch (period) {
      case StatisticsPeriod.sevenDays:
        return endDate.subtract(const Duration(days: 6));
      case StatisticsPeriod.thirtyDays:
        return endDate.subtract(const Duration(days: 29));
      case StatisticsPeriod.threeMonths:
        return DateTime(endDate.year, endDate.month - 3, endDate.day);
      case StatisticsPeriod.month:
        return DateTime(endDate.year, endDate.month, 1);
      case StatisticsPeriod.custom:
        throw StateError('Custom period må beregnes med startDate.');
    }
  }

  DateTime _calculateEndDate({
    required DateTime endDate,
    required StatisticsPeriod period,
  }) {
    if (period == StatisticsPeriod.month) {
      return DateTime(endDate.year, endDate.month + 1, 0);
    }
    return endDate;
  }

  AlcoholStatistics _calculateAlcoholStatistics(List<DailyCheckin> checkins) {
    final sortedCheckins = [...checkins]
      ..sort((a, b) => a.appDate.compareTo(b.appDate));

    final dailyData = <DailyAlcoholStatistic>[];
    int totalUnits = 0;
    int drinkingDays = 0;

    for (final checkin in sortedCheckins) {
      final units = checkin.alcoholUnits;
      totalUnits += units;
      if (units > 0) drinkingDays++;
      dailyData.add(
        DailyAlcoholStatistic(date: _dateOnly(checkin.appDate), units: units),
      );
    }

    final registeredDays = sortedCheckins.length;
    final averageUnitsOnDrinkingDays = drinkingDays == 0
        ? 0.0
        : totalUnits / drinkingDays;
    final highestUnits = sortedCheckins.isEmpty
        ? 0
        : sortedCheckins
              .map((checkin) => checkin.alcoholUnits)
              .reduce((highest, units) => units > highest ? units : highest);

    return AlcoholStatistics(
      totalUnits: totalUnits,
      drinkingDays: drinkingDays,
      registeredDays: registeredDays,
      averageUnitsOnDrinkingDays: averageUnitsOnDrinkingDays,
      highestUnits: highestUnits,
      dailyData: dailyData,
    );
  }

  CravingStatistics _calculateCravingStatistics(List<DailyCheckin> checkins) {
    final scores = checkins
        .map((checkin) => checkin.craving)
        .whereType<int>()
        .toList();

    if (scores.isEmpty) {
      return const CravingStatistics(
        highestCraving: 0,
        daysWithCraving: 0,
        mostCommonScore: 0,
        registeredDays: 0,
      );
    }

    final highestCraving = scores.reduce(
      (highest, score) => score > highest ? score : highest,
    );
    final daysWithCraving = scores.where((score) => score > 1).length;
    final scoreCounts = <int, int>{};

    for (final score in scores) {
      scoreCounts[score] = (scoreCounts[score] ?? 0) + 1;
    }

    final mostCommonScore = scoreCounts.entries.reduce((a, b) {
      if (b.value > a.value) return b;
      if (b.value < a.value) return a;
      return a.key < b.key ? a : b;
    }).key;

    return CravingStatistics(
      highestCraving: highestCraving,
      daysWithCraving: daysWithCraving,
      mostCommonScore: mostCommonScore,
      registeredDays: scores.length,
    );
  }

  MoodStatistics _calculateMoodStatistics(List<DailyCheckin> checkins) {
    final scoreCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (final checkin in checkins) {
      final mood = checkin.mood;
      if (mood != null && mood >= 1 && mood <= 5) {
        scoreCounts[mood] = (scoreCounts[mood] ?? 0) + 1;
      }
    }

    final registeredDays = scoreCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );
    return MoodStatistics(
      scoreCounts: scoreCounts,
      registeredDays: registeredDays,
    );
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
