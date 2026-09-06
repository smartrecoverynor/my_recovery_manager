import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/daily_checkin.dart';
import '../../data/models/user_goal.dart';
import '../../data/repositories/daily_checkin_repository.dart';
import '../../data/repositories/user_goal_repository.dart';

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

  DateTime _focusedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  DateTime _selectedDay = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  final Map<String, DailyCheckin?> _checkins = {};
  final Map<String, UserGoal?> _goals = {};

  static const Color _backgroundColor = Color(0xffF4F8F8);
  static const Color _surfaceColor = Colors.white;

  static const Color _softAqua = Color(0xffDCEEEF);
  static const Color _aqua = Color(0xff69B9C2);
  static const Color _deepTeal = Color(0xff176477);
  static const Color _navy = Color(0xff183545);
  static const Color _textColor = Color(0xff203440);
  static const Color _mutedColor = Color(0xff71858C);

  static const Color _abstinenceBackground =
  Color(0xffEAF3FA);

  static const Color _moderationBackground =
  Color(0xffEAF6F1);

  static const Color _withinColor =
  Color(0xff4F9B74);

  static const Color _nearColor =
  Color(0xffD39A3A);

  static const Color _overColor =
  Color(0xffD86A65);

  static const Color _noRegistrationColor =
  Color(0xff9BAEB2);

  @override
  void initState() {
    super.initState();
    _loadMonth();
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
        : const Color(0xffF7FAFA);

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
            color: const Color(0xffE6EEEE),
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
        color: const Color(0xffF9FBFB),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: const Color(0xffE2EAEA),
        ),
      ),
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Text(
            'U$weekNumber',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 5),
          if (status == _DayStatus.none)
            const Text(
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
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _mutedColor,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(
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
          color: const Color(0xffE1EAEA),
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
            style: const TextStyle(
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
                  ? const Color(0xffF7FAFA)
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
                        style: const TextStyle(
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
                          style: const TextStyle(
                            fontSize: 14,
                            color: _mutedColor,
                          ),
                        ),
                      ],
                      if (goalText != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Mål: $goalText',
                          style: const TextStyle(
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
          color: const Color(0xffE1EAEA),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
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
            color: const Color(0xffE1EAEA),
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
          style: const TextStyle(
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
          style: const TextStyle(
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
          color: const Color(0xffE1EAEA),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Text(
            'Detaljert statistikk',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: _navy,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Her kommer detaljert statistikk basert på '
                'registrerte data.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: _mutedColor,
            ),
          ),
          const SizedBox(height: 18),
          _buildPlaceholderRow(
            Icons.local_bar_outlined,
            'Alkoholbruk',
          ),
          _buildPlaceholderRow(
            Icons.psychology_outlined,
            'Sug/craving',
          ),
          _buildPlaceholderRow(
            Icons.mood_outlined,
            'Humør',
          ),
          _buildPlaceholderRow(
            Icons.picture_as_pdf_outlined,
            'Eksport til PDF',
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderRow(
      IconData icon,
      String title,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 21,
            color: _aqua,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
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
              const Text(
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
                      const Color(0xffE1EAEA),
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
                              style: const TextStyle(
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
                        const Padding(
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