import 'package:flutter/material.dart';
import '../model/lecture_model.dart';

DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

List<DateTime> getFutureClassDate(Lecture lecture, DateTime baseDateTime) {
  final today = DateTime(baseDateTime.year, baseDateTime.month, baseDateTime.day);
  final start = lecture.startDate;
  final end = lecture.endDate;
  final recurringWeekdays = lecture.recurringDays.map(weekdayToInt).toSet();

  final excludedDates = lecture.excludedDates.map(normalize).toSet();
  final makeupDates = lecture.makeupDates.map(normalize).where((d) => d.isAfter(today)).toSet();

  final scheduled = <DateTime>{};

  for (var date = start; !date.isAfter(end); date = date.add(Duration(days: 1))) {
    final d = normalize(date);
    final isAfterSelected = d.isAfter(today) ||
        (d.isAtSameMomentAs(today) && _isTimeSlotFuture(d, baseDateTime, lecture));
    if (isAfterSelected &&
        recurringWeekdays.contains(date.weekday) &&
        !excludedDates.contains(d)) {
      scheduled.add(d);
    }
  }

  scheduled.addAll(makeupDates);

  return scheduled.toList()..sort();
}

bool _isTimeSlotFuture(DateTime date, DateTime baseDateTime, Lecture lecture) {
  final day = _weekdayFromDate(date);
  final slot = lecture.timeSlots.firstWhere(
        (s) => s.day == day,
    orElse: () => LectureTimeSlot(
      day: day,
      startTime: const TimeOfDay(hour: 0, minute: 0),
      endTime: const TimeOfDay(hour: 0, minute: 0),
    ),
  );

  final slotEnd = DateTime(
    baseDateTime.year,
    baseDateTime.month,
    baseDateTime.day,
    slot.endTime.hour,
    slot.endTime.minute,
  );

  return slotEnd.isAfter(baseDateTime);
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
