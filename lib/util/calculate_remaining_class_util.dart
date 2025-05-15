import '../model/lecture_model.dart';

List<DateTime> calculateRemainingClasses(Lecture lecture) {
  final now = DateTime.now();
  final start = lecture.startDate.isAfter(now) ? lecture.startDate : now;
  final end = lecture.endDate;

  final recurringWeekdays =
  lecture.recurringDays.map(weekdayToInt).toSet(); // ✅ 모델 밖 함수 사용

  final Set<DateTime> scheduledDates = {};

  for (var date = start;
  !date.isAfter(end);
  date = date.add(const Duration(days: 1))) {
    if (recurringWeekdays.contains(date.weekday)) {
      scheduledDates.add(DateTime(date.year, date.month, date.day));
    }
  }

  final excluded = lecture.excludedDates
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet();

  final makeup = lecture.makeupDates
      .where((d) => !d.isBefore(now))
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet();

  final remaining = scheduledDates.difference(excluded).union(makeup);
  return remaining.toList();
}
