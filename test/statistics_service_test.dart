import 'package:flutter_test/flutter_test.dart';

import 'package:my_recovery_manager/core/services/statistics_service.dart';
import 'package:my_recovery_manager/data/models/daily_checkin.dart';
import 'package:my_recovery_manager/data/repositories/daily_checkin_repository.dart';

class _FakeDailyCheckinRepository
    extends DailyCheckinRepository {
  final List<DailyCheckin> checkins;

  _FakeDailyCheckinRepository(this.checkins);

  @override
  Future<List<DailyCheckin>> getByDateRange({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    return checkins.where((checkin) {
      final date = DateTime(
        checkin.appDate.year,
        checkin.appDate.month,
        checkin.appDate.day,
      );

      return !date.isBefore(from) &&
          !date.isAfter(to);
    }).toList();
  }
}

DailyCheckin _checkin({
  required DateTime date,
  required int units,
  int? craving,
  int? mood,
}) {
  return DailyCheckin(
    id: 'checkin-${date.toIso8601String()}',
    userId: 'local-user',
    appDate: date,
    mood: mood,
    craving: craving,
    alcoholUnits: units,
    journalText: null,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('StatisticsService - alkohol', () {
    test(
      'beregner total, forbruksdager, registrerte dager, gjennomsnitt og maksimum',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2026, 9, 1),
            units: 0,
          ),
          _checkin(
            date: DateTime(2026, 9, 2),
            units: 2,
          ),
          _checkin(
            date: DateTime(2026, 9, 3),
            units: 4,
          ),
          _checkin(
            date: DateTime(2026, 9, 4),
            units: 0,
          ),
          _checkin(
            date: DateTime(2026, 9, 5),
            units: 6,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getAlcoholStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.thirtyDays,
          endDate: DateTime(2026, 9, 5),
        );

        expect(statistics.totalUnits, 12);
        expect(statistics.drinkingDays, 3);
        expect(statistics.registeredDays, 5);
        expect(
          statistics.averageUnitsOnDrinkingDays,
          closeTo(4.0, 0.001),
        );
        expect(statistics.highestUnits, 6);
      },
    );

    test(
      'registrert 0 enheter teller som registrert dag, men ikke som forbruksdag',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2026, 9, 1),
            units: 0,
          ),
          _checkin(
            date: DateTime(2026, 9, 2),
            units: 0,
          ),
          _checkin(
            date: DateTime(2026, 9, 3),
            units: 3,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getAlcoholStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.sevenDays,
          endDate: DateTime(2026, 9, 7),
        );

        expect(statistics.registeredDays, 3);
        expect(statistics.drinkingDays, 1);
        expect(statistics.totalUnits, 3);
        expect(
          statistics.averageUnitsOnDrinkingDays,
          closeTo(3.0, 0.001),
        );
      },
    );

    test(
      'gir 0 i gjennomsnitt og maksimum når det ikke finnes forbruk',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2026, 9, 1),
            units: 0,
          ),
          _checkin(
            date: DateTime(2026, 9, 2),
            units: 0,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getAlcoholStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.sevenDays,
          endDate: DateTime(2026, 9, 7),
        );

        expect(statistics.totalUnits, 0);
        expect(statistics.drinkingDays, 0);
        expect(statistics.registeredDays, 2);
        expect(
          statistics.averageUnitsOnDrinkingDays,
          0.0,
        );
        expect(statistics.highestUnits, 0);
      },
    );

    test(
      'daglig statistikk inneholder kun registrerte dager',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2026, 9, 2),
            units: 2,
          ),
          _checkin(
            date: DateTime(2026, 9, 4),
            units: 5,
          ),
          _checkin(
            date: DateTime(2026, 9, 6),
            units: 0,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getAlcoholStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.sevenDays,
          endDate: DateTime(2026, 9, 7),
        );

        expect(
          statistics.dailyData.length,
          3,
        );

        expect(
          statistics.dailyData[0].date,
          DateTime(2026, 9, 2),
        );

        expect(
          statistics.dailyData[0].units,
          2,
        );

        expect(
          statistics.dailyData[1].date,
          DateTime(2026, 9, 4),
        );

        expect(
          statistics.dailyData[1].units,
          5,
        );

        expect(
          statistics.dailyData[2].date,
          DateTime(2026, 9, 6),
        );

        expect(
          statistics.dailyData[2].units,
          0,
        );
      },
    );

    test(
      'Måned bruker hele februar når måneden har 28 dager',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2027, 2, 1),
            units: 1,
          ),
          _checkin(
            date: DateTime(2027, 2, 28),
            units: 2,
          ),
          _checkin(
            date: DateTime(2027, 3, 1),
            units: 10,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getAlcoholStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.month,
          endDate: DateTime(2027, 2, 15),
        );

        expect(statistics.totalUnits, 3);
        expect(statistics.registeredDays, 2);
        expect(statistics.dailyData.length, 2);
      },
    );

    test(
      'Måned bruker hele april når måneden har 30 dager',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2026, 4, 1),
            units: 1,
          ),
          _checkin(
            date: DateTime(2026, 4, 30),
            units: 2,
          ),
          _checkin(
            date: DateTime(2026, 5, 1),
            units: 10,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getAlcoholStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.month,
          endDate: DateTime(2026, 4, 15),
        );

        expect(statistics.totalUnits, 3);
        expect(statistics.registeredDays, 2);
        expect(statistics.dailyData.length, 2);
      },
    );

    test(
      'Måned bruker hele august når måneden har 31 dager',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2026, 8, 1),
            units: 1,
          ),
          _checkin(
            date: DateTime(2026, 8, 31),
            units: 2,
          ),
          _checkin(
            date: DateTime(2026, 9, 1),
            units: 10,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getAlcoholStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.month,
          endDate: DateTime(2026, 8, 15),
        );

        expect(statistics.totalUnits, 3);
        expect(statistics.registeredDays, 2);
        expect(statistics.dailyData.length, 2);
      },
    );
  });

  group('mood statistics', () {
    test('calculates number of registrations for each mood score', () async {
      final checkins = [
        _checkin(
          date: DateTime(2026, 8, 1),
          units: 0,
          mood: 1,
        ),
        _checkin(
          date: DateTime(2026, 8, 2),
          units: 0,
          mood: 1,
        ),
        _checkin(
          date: DateTime(2026, 8, 3),
          units: 0,
          mood: 2,
        ),
        _checkin(
          date: DateTime(2026, 8, 4),
          units: 0,
          mood: 4,
        ),
        _checkin(
          date: DateTime(2026, 8, 5),
          units: 0,
          mood: 5,
        ),
        _checkin(
          date: DateTime(2026, 8, 6),
          units: 0,
          mood: null,
        ),
        _checkin(
          date: DateTime(2026, 8, 7),
          units: 0,
          mood: 5,
        ),
      ];

      final repository = _FakeDailyCheckinRepository(checkins);
      final service = StatisticsService(
        checkinRepository: repository,
      );

      final statistics = await service.getMoodStatistics(
        userId: 'local-user',
        period: StatisticsPeriod.sevenDays,
        endDate: DateTime(2026, 8, 7),
      );

      expect(statistics.scoreCounts[1], 2);
      expect(statistics.scoreCounts[2], 1);
      expect(statistics.scoreCounts[3], 0);
      expect(statistics.scoreCounts[4], 1);
      expect(statistics.scoreCounts[5], 2);

      expect(statistics.registeredDays, 6);
    });

    test('returns zero for all mood scores when no mood is registered', () async {
      final checkins = [
        _checkin(
          date: DateTime(2026, 8, 1),
          units: 0,
          mood: null,
        ),
        _checkin(
          date: DateTime(2026, 8, 2),
          units: 0,
          mood: null,
        ),
      ];

      final repository = _FakeDailyCheckinRepository(checkins);
      final service = StatisticsService(
        checkinRepository: repository,
      );

      final statistics = await service.getMoodStatistics(
        userId: 'local-user',
        period: StatisticsPeriod.sevenDays,
        endDate: DateTime(2026, 8, 2),
      );

      expect(statistics.scoreCounts[1], 0);
      expect(statistics.scoreCounts[2], 0);
      expect(statistics.scoreCounts[3], 0);
      expect(statistics.scoreCounts[4], 0);
      expect(statistics.scoreCounts[5], 0);

      expect(statistics.registeredDays, 0);
    });
  });

  group('StatisticsService - craving', () {
    test(
      'beregner høyeste sug, dager med sug og vanligste score',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2026, 9, 1),
            units: 0,
            craving: 1,
          ),
          _checkin(
            date: DateTime(2026, 9, 2),
            units: 0,
            craving: 3,
          ),
          _checkin(
            date: DateTime(2026, 9, 3),
            units: 0,
            craving: 5,
          ),
          _checkin(
            date: DateTime(2026, 9, 4),
            units: 0,
            craving: 5,
          ),
          _checkin(
            date: DateTime(2026, 9, 5),
            units: 0,
            craving: 1,
          ),
          _checkin(
            date: DateTime(2026, 9, 6),
            units: 0,
            craving: null,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getCravingStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.sevenDays,
          endDate: DateTime(2026, 9, 7),
        );

        expect(statistics.highestCraving, 5);
        expect(statistics.daysWithCraving, 3);
        expect(statistics.mostCommonScore, 1);
        expect(statistics.registeredDays, 5);
      },
    );

    test(
      'ved likt antall velges laveste craving-score som vanligste',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2026, 9, 1),
            units: 0,
            craving: 1,
          ),
          _checkin(
            date: DateTime(2026, 9, 2),
            units: 0,
            craving: 1,
          ),
          _checkin(
            date: DateTime(2026, 9, 3),
            units: 0,
            craving: 3,
          ),
          _checkin(
            date: DateTime(2026, 9, 4),
            units: 0,
            craving: 3,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getCravingStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.sevenDays,
          endDate: DateTime(2026, 9, 7),
        );

        expect(statistics.mostCommonScore, 1);
      },
    );

    test(
      'ignorerer dager uten registrert craving',
          () async {
        final repository =
        _FakeDailyCheckinRepository([
          _checkin(
            date: DateTime(2026, 9, 1),
            units: 0,
            craving: null,
          ),
          _checkin(
            date: DateTime(2026, 9, 2),
            units: 0,
            craving: null,
          ),
        ]);

        final service = StatisticsService(
          checkinRepository: repository,
        );

        final statistics =
        await service.getCravingStatistics(
          userId: 'local-user',
          period: StatisticsPeriod.sevenDays,
          endDate: DateTime(2026, 9, 7),
        );

        expect(statistics.highestCraving, 0);
        expect(statistics.daysWithCraving, 0);
        expect(statistics.mostCommonScore, 0);
        expect(statistics.registeredDays, 0);
      },
    );
  });
}