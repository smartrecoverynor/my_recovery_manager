
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:go_router/go_router.dart';

import '../../data/models/daily_checkin.dart';
import '../../data/models/user_goal.dart';
import '../../data/repositories/daily_checkin_repository.dart';
import '../../data/repositories/user_goal_repository.dart';
import '../../core/services/statistics_service.dart';
import '../../core/utils/app_day.dart';

enum _DayStatus {
  none,
  within,
  near,
  over,
}

class StatisticsExportPage extends StatefulWidget {
  const StatisticsExportPage({super.key});

  @override
  State<StatisticsExportPage> createState() =>
      _StatisticsExportPageState();
}

class _StatisticsExportPageState
    extends State<StatisticsExportPage> {
  final DailyCheckinRepository _checkinRepository =
  DailyCheckinRepository();

  final UserGoalRepository _goalRepository =
  UserGoalRepository();

  bool _showMonthlyOverview = true;
  bool _isLoading = true;

  StatisticsPeriod _selectedStatisticsPeriod =
      StatisticsPeriod.sevenDays;

  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime _selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  DateTime _selectedStatisticsMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime? _customStatisticsStartDate;
  DateTime? _customStatisticsEndDate;

  final Map<String, DailyCheckin?> _checkins = {};
  final Map<String, UserGoal?> _goals = {};

  AlcoholStatistics? _alcoholStatistics;
  CravingStatistics? _cravingStatistics;
  MoodStatistics? _moodStatistics;

  Color _backgroundColor = const Color(0xffF4F8F8);
  Color _surfaceColor = Colors.white;

  Color _softAqua = const Color(0xffDCEEEF);
  Color _aqua = const Color(0xff69B9C2);
  Color _deepTeal = const Color(0xff176477);
  Color _navy = const Color(0xff183545);
  Color _textColor = const Color(0xff203440);
  Color _mutedColor = const Color(0xff71858C);

  Color _abstinenceBackground = const Color(0xffEAF3FA);
  Color _moderationBackground = const Color(0xffEAF6F1);

  Color _withinColor = const Color(0xff4F9B74);
  Color _nearColor = const Color(0xffD39A3A);
  Color _overColor = const Color(0xffD86A65);
  Color _noRegistrationColor = const Color(0xff9BAEB2);

  Color _borderColor = const Color(0xffE1EAEA);
  Color _subtleSurfaceColor = const Color(0xffF7FAFA);
  Color _softBorderColor = const Color(0xffE6EEEE);
  Color _weekBorderColor = const Color(0xffE2EAEA);
  Color _weekSurfaceColor = const Color(0xffF9FBFB);

  void _updateThemeColors(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    _backgroundColor = colors.surface;
    _surfaceColor = colors.surfaceContainerLow;
    _softAqua = colors.primaryContainer;
    _aqua = colors.primary;
    _deepTeal = colors.primary;
    _navy = colors.onSurface;
    _textColor = colors.onSurface;
    _mutedColor = colors.onSurfaceVariant;
    _abstinenceBackground = colors.secondaryContainer;
    _moderationBackground = colors.tertiaryContainer;

    _borderColor = colors.outlineVariant;
    _subtleSurfaceColor = colors.surfaceContainer;
    _softBorderColor = colors.outlineVariant;
    _weekBorderColor = colors.outlineVariant;
    _weekSurfaceColor = colors.surfaceContainerLow;

    // Keep the status colors distinct and stable across light/dark mode.
    _withinColor = const Color(0xff4F9B74);
    _nearColor = const Color(0xffD39A3A);
    _overColor = const Color(0xffD86A65);
    _noRegistrationColor = colors.onSurfaceVariant;
  }

  @override
  void initState() {
    super.initState();
    _loadMonth();
    _loadDetailedStatistics();
  }

  Future<void> _loadMonth() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final firstDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );

    final lastDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );

    final daysBefore = firstDay.weekday - 1;
    final daysAfter = 7 - lastDay.weekday;

    final calendarStart =
    firstDay.subtract(Duration(days: daysBefore));

    final calendarEnd =
    lastDay.add(Duration(days: daysAfter));

    final dates = <DateTime>[];

    for (
    DateTime date = calendarStart;
    !date.isAfter(calendarEnd);
    date = date.add(const Duration(days: 1))
    ) {
      dates.add(date);
    }

    try {
      /*
       * Vi henter hele mål-historikken i stedet for å bruke
       * getForDate() direkte for hver kalenderdato.
       *
       * Grunnen er at validFrom/validTo kan inneholde klokkeslett,
       * mens kalenderdatoen representeres som midnatt.
       *
       * Statistikken skal avgjøre hvilket mål som gjaldt på
       * selve datoen, uavhengig av klokkeslettet i databasen.
       */
      final goalHistory = await _goalRepository.getHistory(
        userId: 'local-user',
      );

      final checkinResults = await Future.wait(
        dates.map(
              (date) => _checkinRepository.getByDate(
            userId: 'local-user',
            appDate: date,
          ),
        ),
      );

      final newCheckins = <String, DailyCheckin?>{};
      final newGoals = <String, UserGoal?>{};

      for (int i = 0; i < dates.length; i++) {
        final date = dates[i];
        final key = _dateKey(date);

        newCheckins[key] = checkinResults[i];
        newGoals[key] = _goalForCalendarDate(
          date,
          goalHistory,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _checkins
          ..clear()
          ..addAll(newCheckins);

        _goals
          ..clear()
          ..addAll(newGoals);

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kunne ikke hente statistikken: $e',
          ),
        ),
      );
    }
  }

  Future<void> _loadDetailedStatistics() async {
    try {
      final service = StatisticsService();

      DateTime? startDate;
      DateTime? endDate;

      if (_selectedStatisticsPeriod == StatisticsPeriod.month) {
        endDate = DateTime(
          _selectedStatisticsMonth.year,
          _selectedStatisticsMonth.month + 1,
          0,
        );
      } else if (_selectedStatisticsPeriod == StatisticsPeriod.custom) {
        startDate = _customStatisticsStartDate;
        endDate = _customStatisticsEndDate;

        if (startDate == null || endDate == null) {
          return;
        }
      }

      final statistics = await service.getAlcoholStatistics(
        userId: 'local-user',
        period: _selectedStatisticsPeriod,
        startDate: startDate,
        endDate: endDate,
      );

      final cravingStatistics = await service.getCravingStatistics(
        userId: 'local-user',
        period: _selectedStatisticsPeriod,
        startDate: startDate,
        endDate: endDate,
      );

      final moodStatistics = await service.getMoodStatistics(
        userId: 'local-user',
        period: _selectedStatisticsPeriod,
        startDate: startDate,
        endDate: endDate,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _alcoholStatistics = statistics;
        _cravingStatistics = cravingStatistics;
        _moodStatistics = moodStatistics;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kunne ikke hente detaljert statistikk: $e',
          ),
        ),
      );
    }
  }

  UserGoal? _goalForCalendarDate(
      DateTime date,
      List<UserGoal> goalHistory,
      ) {
    UserGoal? matchingGoal;

    for (final goal in goalHistory) {
      if (!_isOnOrAfterDate(
        date,
        goal.validFrom,
      )) {
        continue;
      }

      if (goal.validTo != null &&
          !_isOnOrBeforeDate(
            date,
            goal.validTo!,
          )) {
        continue;
      }

      if (matchingGoal == null ||
          goal.validFrom.isAfter(
            matchingGoal.validFrom,
          )) {
        matchingGoal = goal;
      }
    }

    return matchingGoal;
  }

  bool _isOnOrAfterDate(
      DateTime date,
      DateTime reference,
      ) {
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final referenceOnly = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );

    return !dateOnly.isBefore(referenceOnly);
  }

  bool _isOnOrBeforeDate(
      DateTime date,
      DateTime reference,
      ) {
    final dateOnly = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final referenceOnly = DateTime(
      reference.year,
      reference.month,
      reference.day,
    );

    return !dateOnly.isAfter(referenceOnly);
  }

  String _dateKey(DateTime date) {
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  DailyCheckin? _checkinForDate(DateTime date) {
    return _checkins[_dateKey(date)];
  }

  UserGoal? _goalForDate(DateTime date) {
    return _goals[_dateKey(date)];
  }

  _DayStatus _dayStatus(
      DateTime date,
      DailyCheckin? checkin,
      UserGoal? goal,
      ) {
    /*
     * Ingen registrering = ingen evaluering.
     *
     * Dette er viktig: vi skal aldri tolke manglende registrering
     * som en alkoholfri dag.
     */
    if (checkin == null) {
      return _DayStatus.none;
    }

    /*
     * Det finnes en registrering, men hvis det ikke finnes et mål
     * som gjelder for datoen, skal vi ikke late som om dagen er
     * "ingen registrering".
     *
     * Vi bruker derfor en nøytral status her.
     */
    if (goal == null) {
      return _DayStatus.none;
    }

    final units = checkin.alcoholUnits;

    switch (goal.goalType) {
      case UserGoalType.abstinence:
        return units == 0
            ? _DayStatus.within
            : _DayStatus.over;

      case UserGoalType.moderation:
        final dailyLimit = goal.dailyLimit;

        if (dailyLimit == null || dailyLimit <= 0) {
          return _DayStatus.within;
        }

        final percentage = units / dailyLimit;

        if (percentage > 1.0) {
          return _DayStatus.over;
        }

        if (percentage >= 0.8) {
          return _DayStatus.near;
        }

        return _DayStatus.within;
    }
  }

  Color _statusColor(_DayStatus status) {
    switch (status) {
      case _DayStatus.within:
        return _withinColor;

      case _DayStatus.near:
        return _nearColor;

      case _DayStatus.over:
        return _overColor;

      case _DayStatus.none:
        return _noRegistrationColor;
    }
  }

  Color _goalBackground(UserGoal? goal) {
    if (goal == null) {
      return _surfaceColor;
    }

    switch (goal.goalType) {
      case UserGoalType.abstinence:
        return _abstinenceBackground;

      case UserGoalType.moderation:
        return _moderationBackground;
    }
  }

  String _monthName(int month) {
    const months = [
      'Januar',
      'Februar',
      'Mars',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[month - 1];
  }

  String _weekdayName(int weekday) {
    const weekdays = [
      'Ma',
      'Ti',
      'On',
      'To',
      'Fr',
      'Lø',
      'Sø',
    ];

    return weekdays[weekday - 1];
  }

  String _fullWeekdayName(int weekday) {
    const weekdays = [
      'Mandag',
      'Tirsdag',
      'Onsdag',
      'Torsdag',
      'Fredag',
      'Lørdag',
      'Søndag',
    ];

    return weekdays[weekday - 1];
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month - 1,
      );

      _selectedDay = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        1,
      );
    });

    _loadMonth();
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(
        _focusedMonth.year,
        _focusedMonth.month + 1,
      );

      _selectedDay = DateTime(
        _focusedMonth.year,
        _focusedMonth.month,
        1,
      );
    });

    _loadMonth();
  }

  List<DateTime> _getCalendarDates() {
    final firstDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month,
      1,
    );

    final lastDay = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    );

    final daysBefore = firstDay.weekday - 1;
    final daysAfter = 7 - lastDay.weekday;

    final calendarStart =
    firstDay.subtract(Duration(days: daysBefore));

    final calendarEnd =
    lastDay.add(Duration(days: daysAfter));

    final dates = <DateTime>[];

    for (
    DateTime date = calendarStart;
    !date.isAfter(calendarEnd);
    date = date.add(const Duration(days: 1))
    ) {
      dates.add(date);
    }

    return dates;
  }

  List<DateTime> _getWeekDates(int weekIndex) {
    final dates = _getCalendarDates();
    final start = weekIndex * 7;

    if (start >= dates.length) {
      return [];
    }

    final end = start + 7;

    return dates.sublist(
      start,
      end > dates.length ? dates.length : end,
    );
  }

  int _isoWeekNumber(DateTime date) {
    final thursday = date.add(
      Duration(days: 4 - date.weekday),
    );

    final firstThursday = DateTime(
      thursday.year,
      1,
      4,
    );

    final firstThursdayMonday = firstThursday.subtract(
      Duration(days: firstThursday.weekday - 1),
    );

    return 1 +
        thursday
            .difference(firstThursdayMonday)
            .inDays ~/
            7;
  }

  _DayStatus _weekStatus(List<DateTime> dates) {
    final registeredDates = dates.where(
          (date) => _checkinForDate(date) != null,
    );

    if (registeredDates.isEmpty) {
      return _DayStatus.none;
    }

    final goals = registeredDates
        .map(_goalForDate)
        .whereType<UserGoal>()
        .toList();

    if (goals.isEmpty) {
      return _DayStatus.none;
    }

    final goalIds = goals.map((goal) => goal.id).toSet();

    /*
     * Dersom målet endres i løpet av en uke, evaluerer vi ikke
     * hele uken mot ett av målene. Dette unngår en misvisende
     * ukesstatus.
     */
    if (goalIds.length != 1) {
      return _DayStatus.none;
    }

    final goal = goals.first;

    if (goal.goalType == UserGoalType.abstinence) {
      final hasAlcohol = registeredDates.any(
            (date) =>
        (_checkinForDate(date)?.alcoholUnits ?? 0) != 0,
      );

      return hasAlcohol
          ? _DayStatus.over
          : _DayStatus.within;
    }

    final weeklyLimit = goal.weeklyLimit;

    if (weeklyLimit == null || weeklyLimit <= 0) {
      return _DayStatus.none;
    }

    final totalUnits = registeredDates.fold<int>(
      0,
          (sum, date) =>
      sum +
          (_checkinForDate(date)?.alcoholUnits ?? 0),
    );

    final percentage = totalUnits / weeklyLimit;

    if (percentage > 1.0) {
      return _DayStatus.over;
    }

    if (percentage >= 0.8) {
      return _DayStatus.near;
    }

    return _DayStatus.within;
  }

  Widget _buildDayCell(
      BuildContext context,
      DateTime date,
      ) {
    final isCurrentMonth =
        date.month == _focusedMonth.month &&
            date.year == _focusedMonth.year;

    final isSelected =
        _dateKey(date) == _dateKey(_selectedDay);

    final checkin = _checkinForDate(date);
    final goal = _goalForDate(date);

    final status = _dayStatus(
      date,
      checkin,
      goal,
    );

    final hasRegistration = checkin != null;

    final backgroundColor = isCurrentMonth
        ? _goalBackground(goal)
        : _subtleSurfaceColor;

    /*
     * Kun registrerte dager får en farget statusprikk.
     * Manglende registrering får en diskret hul sirkel.
     */
    final dotColor = hasRegistration
        ? _statusColor(status)
        : Colors.transparent;

    return GestureDetector(
      onTap: isCurrentMonth
          ? () {
        setState(() {
          _selectedDay = date;
        });
      }
          : null,
      child: Container(
        height: 70,
        padding: const EdgeInsets.only(
          top: 8,
          bottom: 7,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(11),
          border: isSelected
              ? Border.all(
            color: _deepTeal,
            width: 1.5,
          )
              : Border.all(
            color: _softBorderColor,
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: isCurrentMonth
                    ? _textColor
                    : _mutedColor.withValues(
                  alpha: 0.42,
                ),
              ),
            ),
            Container(
              width: hasRegistration ? 11 : 8,
              height: hasRegistration ? 11 : 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: !hasRegistration
                    ? Border.all(
                  color: _noRegistrationColor
                      .withValues(alpha: 0.7),
                  width: 1.2,
                )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekSummary(
      BuildContext context,
      List<DateTime> weekDates,
      ) {
    if (weekDates.isEmpty) {
      return const SizedBox.shrink();
    }

    final status = _weekStatus(weekDates);
    final statusColor = _statusColor(status);

    final weekNumber = _isoWeekNumber(
      weekDates.first,
    );

    return Container(
      height: 70,
      margin: const EdgeInsets.only(
        left: 6,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: _weekSurfaceColor,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: _weekBorderColor,
        ),
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Text(
            'U$weekNumber',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 5),
          if (status == _DayStatus.none)
            Text(
              '–',
              style: TextStyle(
                fontSize: 12,
                color: _mutedColor,
              ),
            )
          else
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final dates = _getCalendarDates();
    final numberOfWeeks = dates.length ~/ 7;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: 2,
            right: 2,
            bottom: 8,
          ),
          child: Row(
            children: [
              ...List.generate(
                7,
                    (index) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        _weekdayName(index + 1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _mutedColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(
                width: 66,
                child: Center(
                  child: Text(
                    'Uke',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _mutedColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(
          numberOfWeeks,
              (weekIndex) {
            final weekDates =
            _getWeekDates(weekIndex);

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 6,
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.center,
                children: [
                  ...weekDates.map(
                        (date) {
                      return Expanded(
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 2,
                          ),
                          child: _buildDayCell(
                            context,
                            date,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(
                    width: 66,
                    child: _buildWeekSummary(
                      context,
                      weekDates,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSelectedDayCard() {
    final checkin =
    _checkinForDate(_selectedDay);

    final goal =
    _goalForDate(_selectedDay);

    final status = _dayStatus(
      _selectedDay,
      checkin,
      goal,
    );

    String statusText;

    switch (status) {
      case _DayStatus.within:
        statusText = 'Innenfor mål';

      case _DayStatus.near:
        statusText = 'Nær grensen';

      case _DayStatus.over:
        statusText = 'Over mål';

      case _DayStatus.none:
        statusText = checkin == null
            ? 'Ingen registrering'
            : 'Ingen aktivt mål';
    }

    final statusColor = checkin == null
        ? _noRegistrationColor
        : _statusColor(status);

    String? goalText;

    if (goal != null) {
      goalText =
      goal.goalType == UserGoalType.abstinence
          ? 'Avholdenhet'
          : 'Moderasjon';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            '${_fullWeekdayName(_selectedDay.weekday)}, '
                '${_selectedDay.day}. '
                '${_monthName(_selectedDay.month)} '
                '${_selectedDay.year}',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: checkin == null
                  ? _subtleSurfaceColor
                  : _goalBackground(goal),
              borderRadius:
              BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  width: 15,
                  height: 15,
                  margin: const EdgeInsets.only(
                    top: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: checkin == null
                        ? Border.all(
                      color: statusColor,
                      width: 1.5,
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textColor,
                        ),
                      ),
                      if (checkin != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          'Registrert alkohol: '
                              '${checkin.alcoholUnits} enheter',
                          style: TextStyle(
                            fontSize: 14,
                            color: _mutedColor,
                          ),
                        ),
                      ],
                      if (goalText != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Mål: $goalText',
                          style: TextStyle(
                            fontSize: 14,
                            color: _mutedColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Forklaring',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 17,
            runSpacing: 10,
            children: [
              _buildLegendItem(
                color: _withinColor,
                label: 'Innenfor mål',
              ),
              _buildLegendItem(
                color: _nearColor,
                label: 'Nær grensen',
              ),
              _buildLegendItem(
                color: _overColor,
                label: 'Over grensen',
              ),
              _buildLegendItem(
                color: _noRegistrationColor,
                label: 'Ingen registrering',
                outlined: true,
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 1,
            color: _borderColor,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: [
              _buildGoalLegendItem(
                color: _moderationBackground,
                label: 'Moderasjon',
              ),
              _buildGoalLegendItem(
                color: _abstinenceBackground,
                label: 'Avholdenhet',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool outlined = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: outlined
                ? Colors.transparent
                : color,
            shape: BoxShape.circle,
            border: outlined
                ? Border.all(
              color: color,
              width: 1.5,
            )
                : null,
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 19,
          height: 19,
          decoration: BoxDecoration(
            color: color,
            borderRadius:
            BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _softAqua,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSectionButton(
              title: 'Månedlig oversikt',
              selected: _showMonthlyOverview,
              onTap: () {
                setState(() {
                  _showMonthlyOverview = true;
                });
              },
            ),
          ),
          Expanded(
            child: _buildSectionButton(
              title: 'Detaljert statistikk',
              selected: !_showMonthlyOverview,
              onTap: () {
                setState(() {
                  _showMonthlyOverview = false;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionButton({
    required String title,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _surfaceColor
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected
                ? FontWeight.w700
                : FontWeight.w500,
            color: selected
                ? _deepTeal
                : _mutedColor,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedStatisticsPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Detaljert statistikk',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Her kommer detaljert statistikk basert på '
                'registrerte data.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: _mutedColor,
            ),
          ),
          const SizedBox(height: 18),
          _buildStatisticsPeriodSelector(),
          _buildSelectedStatisticsPeriodControls(),
          const SizedBox(height: 22),
          _buildAlcoholStatisticsCard(),
          _buildCravingStatisticsCard(),
          _buildMoodStatisticsCard(),
          const SizedBox(height: 18),
          _buildPdfExportButton(),

        ],
      ),
    );
  }

  Widget _buildAlcoholStatisticsCard() {
    final statistics = _alcoholStatistics;

    if (statistics == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Laster statistikk …',
          style: TextStyle(
            fontSize: 14,
            color: _mutedColor,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Alkoholbruk',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildAlcoholStatisticValue(
                  value: '${statistics.totalUnits}',
                  label: 'Totalt',
                ),
              ),
              Expanded(
                child: _buildAlcoholStatisticValue(
                  value: '${statistics.drinkingDays}',
                  label: 'Dager med alkohol',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildAlcoholStatisticValue(
                  value: '${statistics.registeredDays}',
                  label: 'Registrerte dager',
                ),
              ),
              Expanded(
                child: _buildAlcoholStatisticValue(
                  value: statistics.averageUnitsOnDrinkingDays
                      .toStringAsFixed(1),
                  label: 'Snitt på forbruksdager',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildAlcoholStatisticValue(
            value: '${statistics.highestUnits}',
            label: 'Høyeste registrerte forbruk på én dag',
          ),
        ],
      ),
    );
  }

  Widget _buildCravingStatisticsCard() {
    final statistics = _cravingStatistics;

    if (statistics == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Laster statistikk …',
          style: TextStyle(
            fontSize: 14,
            color: _mutedColor,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sug / craving',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildCravingStatisticValue(
                  value: '${statistics.highestCraving}',
                  label: 'Høyeste sug',
                ),
              ),
              Expanded(
                child: _buildCravingStatisticValue(
                  value: '${statistics.daysWithCraving}',
                  label: 'Dager med sug',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCravingStatisticValue(
            value: '${statistics.mostCommonScore}',
            label: 'Vanligste score',
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStatisticsCard() {
    final statistics = _moodStatistics;

    if (statistics == null) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Laster statistikk …',
          style: TextStyle(
            fontSize: 14,
            color: _mutedColor,
          ),
        ),
      );
    }

    const moodLabels = {
      1: 'Veldig bra',
      2: 'Bra',
      3: 'Nøytral',
      4: 'Dårlig',
      5: 'Veldig dårlig',
    };

    final counts = [
      statistics.scoreCounts[1] ?? 0,
      statistics.scoreCounts[2] ?? 0,
      statistics.scoreCounts[3] ?? 0,
      statistics.scoreCounts[4] ?? 0,
      statistics.scoreCounts[5] ?? 0,
    ];

    final maxCount = counts.reduce(
          (a, b) => a > b ? a : b,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Humør',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Antall registreringer per verdi',
            style: TextStyle(
              fontSize: 12,
              color: _mutedColor,
            ),
          ),
          const SizedBox(height: 16),

          for (int score = 1; score <= 5; score++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMoodBar(
                score: score,
                label: moodLabels[score]!,
                count: statistics.scoreCounts[score] ?? 0,
                maxCount: maxCount,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoodBar({
    required int score,
    required String label,
    required int count,
    required int maxCount,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 105,
          child: Text(
            '$score – $label',
            style: TextStyle(
              fontSize: 12,
              color: _textColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final ratio =
              maxCount == 0 ? 0.0 : count / maxCount;

              return Container(
                height: 18,
                decoration: BoxDecoration(
                  color: _softAqua,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: ratio,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _aqua,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 24,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _navy,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCravingStatisticValue({
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _deepTeal,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAlcoholStatisticValue({
    required String value,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: _deepTeal,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: _mutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildStatisticsPeriodButton(
            title: '7 dager',
            period: StatisticsPeriod.sevenDays,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _buildStatisticsPeriodButton(
            title: '30 dager',
            period: StatisticsPeriod.thirtyDays,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _buildStatisticsPeriodButton(
            title: '3 mnd',
            period: StatisticsPeriod.threeMonths,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _buildStatisticsPeriodButton(
            title: 'Måned',
            period: StatisticsPeriod.month,
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: _buildStatisticsPeriodButton(
            title: 'Egendef.',
            period: StatisticsPeriod.custom,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedStatisticsPeriodControls() {
    if (_selectedStatisticsPeriod == StatisticsPeriod.month) {
      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Forrige måned',
              onPressed: _previousStatisticsMonth,
              icon: const Icon(Icons.chevron_left_rounded),
              color: _deepTeal,
            ),
            Expanded(
              child: Text(
                '${_monthName(_selectedStatisticsMonth.month)} ${_selectedStatisticsMonth.year}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _navy,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Neste måned',
              onPressed: _nextStatisticsMonth,
              icon: const Icon(Icons.chevron_right_rounded),
              color: _deepTeal,
            ),
          ],
        ),
      );
    }

    if (_selectedStatisticsPeriod == StatisticsPeriod.custom) {
      final start = _customStatisticsStartDate;
      final end = _customStatisticsEndDate;

      return Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.fromLTRB(14, 11, 8, 11),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.date_range_outlined,
              size: 19,
              color: _deepTeal,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                start == null || end == null
                    ? 'Velg fra- og til-dato'
                    : '${_formatDate(start)} – ${_formatDate(end)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ),
            TextButton(
              onPressed: _selectCustomStatisticsRange,
              child: const Text('Endre'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _previousStatisticsMonth() {
    setState(() {
      _selectedStatisticsMonth = DateTime(
        _selectedStatisticsMonth.year,
        _selectedStatisticsMonth.month - 1,
      );
    });
    _loadDetailedStatistics();
  }

  void _nextStatisticsMonth() {
    setState(() {
      _selectedStatisticsMonth = DateTime(
        _selectedStatisticsMonth.year,
        _selectedStatisticsMonth.month + 1,
      );
    });
    _loadDetailedStatistics();
  }

  Future<void> _selectCustomStatisticsRange() async {
    final now = getAppDate(DateTime.now());
    final initialStart = _customStatisticsStartDate ?? now.subtract(const Duration(days: 6));
    final initialEnd = _customStatisticsEndDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initialStart.isBefore(DateTime(2020)) ? DateTime(2020) : initialStart,
        end: initialEnd.isAfter(now) ? now : initialEnd,
      ),
      helpText: 'Velg periode',
      cancelText: 'Avbryt',
      confirmText: 'Velg',
      saveText: 'Velg',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedStatisticsPeriod = StatisticsPeriod.custom;
      _customStatisticsStartDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      );
      _customStatisticsEndDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
      );
    });

    _loadDetailedStatistics();
  }

  Widget _buildStatisticsPeriodButton({
    required String title,
    required StatisticsPeriod period,
  }) {
    final selected =
        _selectedStatisticsPeriod == period;

    return GestureDetector(
      onTap: () async {
        if (period == StatisticsPeriod.month) {
          if (_selectedStatisticsPeriod != period) {
            setState(() {
              _selectedStatisticsPeriod = period;
            });
            _loadDetailedStatistics();
          }
          return;
        }

        if (period == StatisticsPeriod.custom) {
          await _selectCustomStatisticsRange();
          return;
        }

        if (_selectedStatisticsPeriod == period) {
          return;
        }

        setState(() {
          _selectedStatisticsPeriod = period;
        });

        _loadDetailedStatistics();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 6,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _softAqua
              : _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? _aqua
                : _borderColor,
          ),
        ),
        child: SizedBox(
          height: 18,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? _deepTeal
                    : _mutedColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Widget _buildPdfExportButton() {
    final canExport =
        _alcoholStatistics != null &&
        _cravingStatistics != null &&
        _moodStatistics != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canExport ? _exportStatisticsPdf : null,
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: const Text('Lag og del beskyttet PDF'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _deepTeal,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          disabledBackgroundColor: _softAqua,
          disabledForegroundColor: _mutedColor,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  String _statisticsPeriodTitle() {
    switch (_selectedStatisticsPeriod) {
      case StatisticsPeriod.sevenDays:
        return 'Siste 7 dager';
      case StatisticsPeriod.thirtyDays:
        return 'Siste 30 dager';
      case StatisticsPeriod.threeMonths:
        return 'Siste 3 måneder';
      case StatisticsPeriod.month:
        return '${_monthName(_selectedStatisticsMonth.month)} ${_selectedStatisticsMonth.year}';
      case StatisticsPeriod.custom:
        if (_customStatisticsStartDate != null &&
            _customStatisticsEndDate != null) {
          return '${_formatDate(_customStatisticsStartDate!)} – ${_formatDate(_customStatisticsEndDate!)}';
        }
        return 'Egendefinert periode';
    }
  }

  (DateTime, DateTime) _statisticsExportRange() {
    final today = getAppDate(DateTime.now());

    switch (_selectedStatisticsPeriod) {
      case StatisticsPeriod.sevenDays:
        return (
          today.subtract(const Duration(days: 6)),
          today,
        );
      case StatisticsPeriod.thirtyDays:
        return (
          today.subtract(const Duration(days: 29)),
          today,
        );
      case StatisticsPeriod.threeMonths:
        return (
          DateTime(today.year, today.month - 3, today.day),
          today,
        );
      case StatisticsPeriod.month:
        return (
          DateTime(
            _selectedStatisticsMonth.year,
            _selectedStatisticsMonth.month,
            1,
          ),
          DateTime(
            _selectedStatisticsMonth.year,
            _selectedStatisticsMonth.month + 1,
            0,
          ),
        );
      case StatisticsPeriod.custom:
        return (
          _customStatisticsStartDate ?? today,
          _customStatisticsEndDate ?? today,
        );
    }
  }

  String _pdfDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}. '
        '${date.month.toString().padLeft(2, '0')}. '
        '${date.year}';
  }


  String _generatePdfPassword() {
    const alphabet =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    final random = Random.secure();

    return List.generate(
      20,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  Uint8List _encryptPdf(
    Uint8List inputBytes, {
    required String userPassword,
    required String ownerPassword,
  }) {
    final document = sf.PdfDocument(inputBytes: inputBytes);

    try {
      final security = document.security;
      security.userPassword = userPassword;
      security.ownerPassword = ownerPassword;
      security.algorithm = sf.PdfEncryptionAlgorithm.aesx256Bit;

      return Uint8List.fromList(document.saveSync());
    } finally {
      document.dispose();
    }
  }

  Future<void> _showProtectedPdfDialog({
    required Uint8List bytes,
    required String filename,
    required String password,
  }) async {
    var copied = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> copyPassword() async {
              await Clipboard.setData(
                ClipboardData(text: password),
              );

              if (!dialogContext.mounted) return;

              setDialogState(() {
                copied = true;
              });
            }

            Future<void> sharePdf() async {
              Navigator.of(dialogContext).pop();

              await Printing.sharePdf(
                bytes: bytes,
                filename: filename,
              );
            }

            return AlertDialog(
              title: const Text('Rapporten er beskyttet'),
              content: Text(
                'PDF-en er kryptert med AES-256 og kan bare åpnes med passordet under. '
                'Send passordet via en annen kanal enn selve PDF-filen, for eksempel SMS eller telefon.',
              ),
              actions: [
                SelectableText(
                  password,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                TextButton.icon(
                  onPressed: copyPassword,
                  icon: Icon(
                    copied
                        ? Icons.check_rounded
                        : Icons.copy_rounded,
                  ),
                  label: Text(copied ? 'Kopiert' : 'Kopier passord'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Avbryt'),
                ),
                FilledButton.icon(
                  onPressed: sharePdf,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Del rapport'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _exportStatisticsPdf() async {
    final alcohol = _alcoholStatistics;
    final craving = _cravingStatistics;
    final mood = _moodStatistics;

    if (alcohol == null || craving == null || mood == null) {
      return;
    }

    try {
      final regularFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
      );
      final boldFont = pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
      );

      final range = _statisticsExportRange();
      final periodTitle = _statisticsPeriodTitle();
      final totalDays = range.$2.difference(range.$1).inDays + 1;

      // Hent alle registreringer i perioden slik at alkohol, sug og humør
      // kan vises på samme datoakse i rapporten.
      final periodCheckins = await _checkinRepository.getByDateRange(
        userId: 'local-user',
        from: range.$1,
        to: range.$2,
      );

      final checkinsByDate = <String, DailyCheckin>{
        for (final checkin in periodCheckins)
          _dateKey(checkin.appDate): checkin,
      };
      final registrationRate = totalDays == 0
          ? 0.0
          : alcohol.registeredDays / totalDays;
      final alcoholFreeRegisteredDays =
          (alcohol.registeredDays - alcohol.drinkingDays).clamp(0, totalDays);

      // DailyCheckin mood values are: 1 = very good, 5 = very bad.
      const moodLabels = <int, String>{
        1: 'Veldig bra',
        2: 'Bra',
        3: 'Nøytral',
        4: 'Dårlig',
        5: 'Veldig dårlig',
      };

      final dailyUnits = <String, int>{
        for (final day in alcohol.dailyData)
          _dateKey(day.date): day.units,
      };

      final teal = PdfColor.fromInt(0xff176477);
      final navy = PdfColor.fromInt(0xff183545);
      final text = PdfColor.fromInt(0xff203440);
      final muted = PdfColor.fromInt(0xff71858C);
      final line = PdfColor.fromInt(0xffDCE5E6);
      final pageBackground = PdfColor.fromInt(0xffFBFCFC);

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: regularFont,
          bold: boldFont,
        ),
      );

      pw.Widget sectionTitle(String title) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: navy,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Container(height: 1, color: line),
            pw.SizedBox(height: 10),
          ],
        );
      }

      pw.Widget metric(
        String value,
        String label, {
        bool emphasized = false,
      }) {
        return pw.Container(
          padding: const pw.EdgeInsets.only(right: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: emphasized ? 22 : 17,
                  fontWeight: pw.FontWeight.bold,
                  color: emphasized ? teal : navy,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 8.5, color: muted),
              ),
            ],
          ),
        );
      }

      pw.Widget quietNote(String value) {
        return pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8.5,
            color: muted,
            lineSpacing: 2,
          ),
        );
      }

      pw.Widget moodBars() {
        final maxCount = mood.scoreCounts.values.fold<int>(
          0,
          (max, value) => value > max ? value : max,
        );

        return pw.Column(
          children: List.generate(5, (index) {
            final score = index + 1;
            final count = mood.scoreCounts[score] ?? 0;
            final fraction = maxCount == 0 ? 0.0 : count / maxCount;

            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 7),
              child: pw.Row(
                children: [
                  pw.SizedBox(
                    width: 92,
                    child: pw.Text(
                      moodLabels[score]!,
                      style: pw.TextStyle(fontSize: 8.5, color: text),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Container(
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: pageBackground,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Align(
                        alignment: pw.Alignment.centerLeft,
                        child: pw.Container(
                          width: 280 * fraction,
                          height: 8,
                          decoration: pw.BoxDecoration(
                            color: teal,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.SizedBox(
                    width: 18,
                    child: pw.Text(
                      '$count',
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: navy,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      }

      String escapeSvg(String value) {
        return value
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;');
      }

      String svgDate(DateTime date) {
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
      }

      String buildStackedLineChartSvg({
        required String title,
        required List<double?> values,
        required double minValue,
        required double maxValue,
        required List<String> yLabels,
        required List<DateTime> dates,
        required bool showDateLabels,
      }) {
        const width = 520.0;
        const height = 112.0;
        const left = 34.0;
        const top = 18.0;
        const right = 12.0;
        const bottom = 18.0;
        final plotWidth = width - left - right;
        final plotHeight = height - top - bottom;

        final svg = StringBuffer()
          ..writeln('<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height">')
          ..writeln('<rect width="100%" height="100%" fill="#FFFFFF"/>')
          ..writeln('<text x="$left" y="11" font-family="Noto Sans" font-size="9" font-weight="700" fill="#183545">${escapeSvg(title)}</text>');

        for (int i = 0; i < yLabels.length; i++) {
          final value = double.tryParse(yLabels[i].replaceAll(',', '.')) ?? 0;
          final normalized = maxValue <= minValue
              ? 0.0
              : (value - minValue) / (maxValue - minValue);
          final safeNormalized = normalized.clamp(0.0, 1.0);
          final y = top + plotHeight * (1 - safeNormalized);

          svg
            ..writeln('<line x1="$left" y1="$y" x2="${width - right}" y2="$y" stroke="#E4ECEC" stroke-width="0.7"/>')
            ..writeln('<text x="${left - 7}" y="${y + 3}" text-anchor="end" font-family="Noto Sans" font-size="7" fill="#71858C">${escapeSvg(yLabels[i])}</text>');
        }

        final xAxisY = top + plotHeight;
        svg.writeln('<line x1="$left" y1="$xAxisY" x2="${width - right}" y2="$xAxisY" stroke="#BFCFD1" stroke-width="0.8"/>');

        final pathSegments = <String>[];
        final circlePoints = <String>[];
        for (int i = 0; i < values.length; i++) {
          final value = values[i];
          if (value == null) continue;

          final x = values.length <= 1
              ? left + plotWidth / 2
              : left + plotWidth * i / (values.length - 1);
          final normalized = maxValue <= minValue
              ? 0.0
              : (value - minValue) / (maxValue - minValue);
          final safeNormalized = normalized.clamp(0.0, 1.0);
          final y = top + plotHeight * (1 - safeNormalized);

          circlePoints.add('<circle cx="$x" cy="$y" r="2.1" fill="#176477"/>');

          int next = i + 1;
          if (next < values.length && values[next] != null) {
            final nextValue = values[next]!;
            final nextX = values.length <= 1
                ? left + plotWidth / 2
                : left + plotWidth * next / (values.length - 1);
            final nextNormalized = maxValue <= minValue
                ? 0.0
                : (nextValue - minValue) / (maxValue - minValue);
            final nextSafeNormalized = nextNormalized.clamp(0.0, 1.0);
            final nextY = top + plotHeight * (1 - nextSafeNormalized);
            pathSegments.add('<line x1="$x" y1="$y" x2="$nextX" y2="$nextY" stroke="#176477" stroke-width="1.4" stroke-linecap="round"/>');
          }
        }

        svg
          ..writeln(pathSegments.join())
          ..writeln(circlePoints.join());

        if (showDateLabels && dates.isNotEmpty) {
          final labelEvery = dates.length <= 10
              ? 1
              : dates.length <= 31
                  ? 5
                  : dates.length <= 62
                      ? 10
                      : 15;

          for (int i = 0; i < dates.length; i++) {
            final show = i == 0 ||
                i == dates.length - 1 ||
                i % labelEvery == 0;
            if (!show) continue;

            final x = dates.length <= 1
                ? left + plotWidth / 2
                : left + plotWidth * i / (dates.length - 1);

            svg
              ..writeln('<line x1="$x" y1="$xAxisY" x2="$x" y2="${xAxisY + 3}" stroke="#BFCFD1" stroke-width="0.7"/>')
              ..writeln('<text x="$x" y="${height - 3}" text-anchor="middle" font-family="Noto Sans" font-size="6.5" fill="#71858C">${svgDate(dates[i])}</text>');
          }
        }

        svg.writeln('</svg>');
        return svg.toString();
      }

      pw.Widget stackedTimeSeriesCharts() {
        final dates = List<DateTime>.generate(
          totalDays,
          (index) => range.$1.add(Duration(days: index)),
        );

        final alcoholValues = dates.map<double?>((date) {
          final checkin = checkinsByDate[_dateKey(date)];
          return checkin?.alcoholUnits.toDouble();
        }).toList();

        final cravingValues = dates.map<double?>((date) {
          final value = checkinsByDate[_dateKey(date)]?.craving;
          if (value == null || value < 1 || value > 10) return null;
          return value.toDouble();
        }).toList();

        final moodValues = dates.map<double?>((date) {
          final value = checkinsByDate[_dateKey(date)]?.mood;
          if (value == null || value < 1 || value > 5) return null;
          return value.toDouble();
        }).toList();

        final alcoholMax = alcohol.highestUnits > 0
            ? alcohol.highestUnits.toDouble()
            : 1.0;

        return pw.Column(
          children: [
            pw.SvgImage(
              svg: buildStackedLineChartSvg(
                title: 'ALKOHOL',
                values: alcoholValues,
                minValue: 0,
                maxValue: alcoholMax,
                yLabels: List.generate(
                  alcohol.highestUnits > 0 ? alcohol.highestUnits + 1 : 2,
                  (index) => '$index',
                ),
                dates: dates,
                showDateLabels: false,
              ),
              width: double.infinity,
            ),
            pw.SvgImage(
              svg: buildStackedLineChartSvg(
                title: 'SUG / CRAVING',
                values: cravingValues,
                minValue: 1,
                maxValue: 10,
                yLabels: const ['1', '3', '5', '7', '10'],
                dates: dates,
                showDateLabels: false,
              ),
              width: double.infinity,
            ),
            pw.SvgImage(
              svg: buildStackedLineChartSvg(
                title: 'HUMØR',
                values: moodValues,
                minValue: 1,
                maxValue: 5,
                yLabels: const ['1', '2', '3', '4', '5'],
                dates: dates,
                showDateLabels: true,
              ),
              width: double.infinity,
            ),
          ],
        );
      }

      pw.Widget registrationStrip() {
        final dayCount = totalDays;
        final cellWidth = dayCount > 62 ? 5.0 : dayCount > 31 ? 8.0 : 13.0;
        final gap = dayCount > 62 ? 1.0 : 2.0;

        final cells = <pw.Widget>[];
        for (int i = 0; i < dayCount; i++) {
          final date = range.$1.add(Duration(days: i));
          final registered = dailyUnits.containsKey(_dateKey(date));
          cells.add(
            pw.Container(
              width: cellWidth,
              height: cellWidth,
              margin: pw.EdgeInsets.only(right: gap),
              decoration: pw.BoxDecoration(
                color: registered ? teal : pageBackground,
                border: pw.Border.all(color: line, width: 0.5),
                borderRadius: pw.BorderRadius.circular(1.5),
              ),
            ),
          );
        }

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Wrap(children: cells),
            pw.SizedBox(height: 7),
            pw.Row(
              children: [
                pw.Container(
                  width: 7,
                  height: 7,
                  decoration: pw.BoxDecoration(
                    color: teal,
                    borderRadius: pw.BorderRadius.circular(1.5),
                  ),
                ),
                pw.SizedBox(width: 5),
                quietNote('Registrert'),
                pw.SizedBox(width: 14),
                pw.Container(
                  width: 7,
                  height: 7,
                  decoration: pw.BoxDecoration(
                    color: pageBackground,
                    border: pw.Border.all(color: line, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(1.5),
                  ),
                ),
                pw.SizedBox(width: 5),
                quietNote('Ingen registrering'),
              ],
            ),
          ],
        );
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 42),
          footer: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: line, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'My Recovery Manager',
                  style: pw.TextStyle(fontSize: 7.5, color: muted),
                ),
                pw.Text(
                  'Side ${context.pageNumber} av ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, color: muted),
                ),
              ],
            ),
          ),
          build: (context) => [
            pw.Text(
              'My Recovery Manager',
              style: pw.TextStyle(
                fontSize: 23,
                fontWeight: pw.FontWeight.bold,
                color: navy,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Statistikk og utvikling',
              style: pw.TextStyle(fontSize: 12, color: teal),
            ),
            pw.SizedBox(height: 18),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        periodTitle,
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                          color: navy,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        '${_pdfDate(range.$1)} – ${_pdfDate(range.$2)}',
                        style: pw.TextStyle(fontSize: 8.5, color: muted),
                      ),
                    ],
                  ),
                ),
                pw.Text(
                  '${(registrationRate * 100).round()} % registrert',
                  style: pw.TextStyle(fontSize: 8.5, color: muted),
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 13,
              ),
              decoration: pw.BoxDecoration(
                color: pageBackground,
                border: pw.Border(
                  left: pw.BorderSide(color: teal, width: 2),
                ),
              ),
              child: pw.Text(
                _buildPdfSummaryText(
                  alcohol: alcohol,
                  totalDays: totalDays,
                  registrationRate: registrationRate,
                ),
                style: pw.TextStyle(
                  fontSize: 9.5,
                  color: text,
                  lineSpacing: 2,
                ),
              ),
            ),
            pw.SizedBox(height: 22),
            sectionTitle('Alkoholbruk'),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                metric('${alcohol.totalUnits}', 'Alkoholenheter', emphasized: true),
                metric('${alcohol.drinkingDays}', 'Dager med alkohol'),
                metric('$alcoholFreeRegisteredDays', 'Registrerte alkoholfrie dager'),
                metric(
                  alcohol.averageUnitsOnDrinkingDays.toStringAsFixed(1),
                  'Snitt per dag med alkohol',
                ),
              ],
            ),
            pw.SizedBox(height: 13),
            pw.Text(
              'Høyeste registrerte forbruk på én dag: ${alcohol.highestUnits} enheter',
              style: pw.TextStyle(fontSize: 8.5, color: muted),
            ),
            pw.SizedBox(height: 22),
            sectionTitle('Humør'),
            moodBars(),
            pw.SizedBox(height: 4),
            quietNote('Registrerte humørdager: ${mood.registeredDays}'),
            pw.SizedBox(height: 22),
            sectionTitle('Sug / craving'),
            pw.Row(
              children: [
                metric('${craving.highestCraving}', 'Høyeste registrerte sug'),
                metric('${craving.daysWithCraving}', 'Dager med sug'),
                metric('${craving.mostCommonScore}', 'Vanligste score'),
              ],
            ),
          ],
        ),
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.fromLTRB(42, 42, 42, 42),
          footer: (context) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: line, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'My Recovery Manager',
                  style: pw.TextStyle(fontSize: 7.5, color: muted),
                ),
                pw.Text(
                  'Side ${context.pageNumber} av ${context.pagesCount}',
                  style: pw.TextStyle(fontSize: 7.5, color: muted),
                ),
              ],
            ),
          ),
          build: (context) => [
            pw.Text(
              'Utvikling og registrering',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: navy,
              ),
            ),
            pw.SizedBox(height: 4),
            quietNote('Utviklingen vises for alle dager i den valgte perioden.'),
            pw.SizedBox(height: 20),
            sectionTitle('Utvikling over tid'),
            quietNote(
              'De tre grafene deler samme datoakse. Manglende registrering vises som et opphold i kurven og skal ikke tolkes som en verdi på null.',
            ),
            pw.SizedBox(height: 8),
            stackedTimeSeriesCharts(),
            pw.SizedBox(height: 8),
            quietNote(
              'Alkohol: 0 = registrert alkoholfri dag. Sug: 1–10. Humør: 1 = Veldig bra, 5 = Veldig dårlig.',
            ),
            pw.SizedBox(height: 18),
            sectionTitle('Registreringsgrad'),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                metric(
                  '${alcohol.registeredDays} av $totalDays',
                  'dager registrert',
                  emphasized: true,
                ),
                metric('${(registrationRate * 100).round()} %', 'registreringsgrad'),
              ],
            ),
            pw.SizedBox(height: 10),
            registrationStrip(),
            pw.SizedBox(height: 18),
            sectionTitle('Om statistikken'),
            quietNote(
              'Statistikken bygger på registreringene som er gjort i My Recovery Manager i den valgte perioden. Dager uten registrering kan ikke tolkes som dager uten alkoholbruk eller andre forhold.',
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.only(top: 12),
              decoration: pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: line, width: 0.5)),
              ),
              child: quietNote(
                'Rapporten er et verktøy for oversikt og egenrefleksjon og erstatter ikke individuell medisinsk eller psykologisk vurdering.',
              ),
            ),
          ],
        ),
      );

      final unencryptedBytes = await pdf.save();
      final password = _generatePdfPassword();
      final ownerPassword = _generatePdfPassword();
      final encryptedBytes = _encryptPdf(
        unencryptedBytes,
        userPassword: password,
        ownerPassword: ownerPassword,
      );

      final filename =
          'MRM_statistikk_${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}.pdf';

      if (!mounted) return;

      await _showProtectedPdfDialog(
        bytes: encryptedBytes,
        filename: filename,
        password: password,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kunne ikke lage PDF: $e'),
        ),
      );
    }
  }

  String _buildPdfSummaryText({
    required AlcoholStatistics alcohol,
    required int totalDays,
    required double registrationRate,
  }) {
    if (alcohol.registeredDays == 0) {
      return 'Det er ingen registrerte dager i den valgte perioden. Statistikken gir derfor ikke grunnlag for å beskrive alkoholbruk eller utvikling.';
    }

    final parts = <String>[];

    if (alcohol.drinkingDays == 0) {
      parts.add(
        'Det er ikke registrert alkoholbruk på noen av de ${alcohol.registeredDays} registrerte dagene.',
      );
    } else {
      parts.add(
        'Det er registrert alkoholbruk på ${alcohol.drinkingDays} av ${alcohol.registeredDays} registrerte dager, med totalt ${alcohol.totalUnits} alkoholenheter.',
      );
    }

    if (alcohol.drinkingDays > 0) {
      parts.add(
        'Gjennomsnittlig registrert inntak på dager med alkohol var ${alcohol.averageUnitsOnDrinkingDays.toStringAsFixed(1)} enheter.',
      );
    }

    parts.add(
      'Det er registrert data på ${(registrationRate * 100).round()} % av dagene i perioden.',
    );

    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    _updateThemeColors(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          color: _deepTeal,
          onPressed: () {
            context.go('/dashboard');
          },
        ),
        title: Text(
          'Statistikk og eksport',
          style: TextStyle(
            color: _navy,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            8,
            18,
            32,
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Se utviklingen din over tid og få en '
                    'samlet oversikt over registrerte data.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: _mutedColor,
                ),
              ),
              const SizedBox(height: 22),
              _buildSectionSelector(),
              const SizedBox(height: 20),
              if (_showMonthlyOverview) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    15,
                  ),
                  decoration: BoxDecoration(
                    color: _surfaceColor,
                    borderRadius:
                    BorderRadius.circular(19),
                    border: Border.all(
                      color:
                      _borderColor,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed:
                            _previousMonth,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                              size: 27,
                            ),
                            color: _deepTeal,
                          ),
                          Expanded(
                            child: Text(
                              '${_monthName(_focusedMonth.month)} '
                                  '${_focusedMonth.year}',
                              textAlign:
                              TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w700,
                                color: _navy,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed:
                            _nextMonth,
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                              size: 27,
                            ),
                            color: _deepTeal,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (_isLoading)
                        Padding(
                          padding:
                          EdgeInsets.symmetric(
                            vertical: 50,
                          ),
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      else
                        _buildCalendar(),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                _buildSelectedDayCard(),
                const SizedBox(height: 15),
                _buildLegend(),
              ] else ...[
                _buildDetailedStatisticsPlaceholder(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
