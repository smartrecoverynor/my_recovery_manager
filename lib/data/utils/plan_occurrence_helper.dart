import '../models/plan.dart';

class PlanOccurrenceHelper {
  static List<DateTime> getOccurrences(Plan plan) {
    final occurrences = <DateTime>[];

    final start = DateTime(
      plan.plannedDate.year,
      plan.plannedDate.month,
      plan.plannedDate.day,
    );

    if (plan.repeat == 'Ingen') {
      return [start];
    }

    final maxOccurrences = plan.repeatCount ?? 999;

    final until = plan.repeatUntil;

    DateTime current = start;

    for (int i = 0; i < maxOccurrences; i++) {
      if (until != null && current.isAfter(until)) {
        break;
      }

      occurrences.add(current);

      if (plan.repeat == 'Daglig') {
        current = current.add(const Duration(days: 1));
      } else if (plan.repeat == 'Ukentlig') {
        current = current.add(const Duration(days: 7));
      } else if (plan.repeat == 'Månedlig') {
        current = _addMonth(current);
      } else {
        break;
      }
    }

    return occurrences;
  }

  static DateTime _addMonth(DateTime date) {
    final nextMonth = date.month == 12 ? 1 : date.month + 1;

    final nextYear = date.month == 12 ? date.year + 1 : date.year;

    final lastDayOfMonth = DateTime(nextYear, nextMonth + 1, 0).day;

    final day = date.day > lastDayOfMonth ? lastDayOfMonth : date.day;

    return DateTime(nextYear, nextMonth, day);
  }
}
