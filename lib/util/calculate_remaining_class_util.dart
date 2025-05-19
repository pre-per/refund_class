import 'package:flutter/material.dart';
import '../model/lecture_model.dart';

DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

List<DateTime> getFutureClassDate(Lecture lecture) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = lecture.startDate;
  final end = lecture.endDate;
  final recurringWeekdays = lecture.recurringDays.map(weekdayToInt).toSet();

  final scheduled = <DateTime>[];

  for (var date = start; !date.isAfter(end); date = date.add(Duration(days: 1))) {
    final d = normalize(date);
    final isAfterNow = d.isAfter(today) || (d.isAtSameMomentAs(today) && _isTimeSlotFuture(d, lecture));
    if (isAfterNow &&
        recurringWeekdays.contains(date.weekday) &&
        !lecture.excludedDates.map(normalize).contains(d) &&
        !lecture.makeupDates.map(normalize).contains(d)) {
      scheduled.add(d);
    }
  }

  return scheduled;
}

bool _isTimeSlotFuture(DateTime date, Lecture lecture) {
  final now = TimeOfDay.now();
  final day = _weekdayFromDate(date);
  final slot = lecture.timeSlots.firstWhere(
        (s) => s.day == day,
    orElse: () => LectureTimeSlot(
      day: day,
      startTime: const TimeOfDay(hour: 0, minute: 0),
      endTime: const TimeOfDay(hour: 0, minute: 0),
    ),
  );
  return slot.endTime.hour > now.hour ||
      (slot.endTime.hour == now.hour && slot.endTime.minute > now.minute);
}

Weekday _weekdayFromDate(DateTime date) {
  switch (date.weekday) {
    case DateTime.monday:
      return Weekday.mon;
    case DateTime.tuesday:
      return Weekday.tue;
    case DateTime.wednesday:
      return Weekday.wed;
    case DateTime.thursday:
      return Weekday.thu;
    case DateTime.friday:
      return Weekday.fri;
    case DateTime.saturday:
      return Weekday.sat;
    case DateTime.sunday:
      return Weekday.sun;
    default:
      throw ArgumentError('Invalid weekday: ${date.weekday}');
  }
}
