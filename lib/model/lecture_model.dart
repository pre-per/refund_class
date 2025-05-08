enum Weekday { mon, tue, wed, thu, fri, sat, sun }

String weekdayToString(Weekday day) => day.name;

Weekday weekdayFromString(String value) =>
    Weekday.values.firstWhere((e) => e.name == value);

class Lecture {
  final String? id;
  final String title;
  final List<Weekday> recurringDays;
  final DateTime startDate;
  final DateTime endDate;
  final int totalFee;
  final int totalSessions;
  int remainingSessions;
  String memo;
  final List<DateTime> excludedDates;
  final List<DateTime> makeupDates;

  Lecture({
    this.id,
    required this.title,
    required this.recurringDays,
    required this.startDate,
    required this.endDate,
    required this.totalFee,
    required this.totalSessions,
    required this.excludedDates,
    required this.makeupDates,
    String? memo,
    int? remainingSessions,
  }) : memo = memo ?? '',
       remainingSessions = remainingSessions ?? -1;

  Lecture copyWith({
    String? id,
    String? title,
    List<Weekday>? recurringDays,
    DateTime? startDate,
    DateTime? endDate,
    int? totalFee,
    int? totalSessions,
    int? remainingSessions,
    String? memo,
    List<DateTime>? excludedDates,
    List<DateTime>? makeupDates,
  }) {
    return Lecture(
      id: id ?? this.id,
      title: title ?? this.title,
      recurringDays: recurringDays ?? this.recurringDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalFee: totalFee ?? this.totalFee,
      totalSessions: totalSessions ?? this.totalSessions,
      remainingSessions: remainingSessions ?? this.remainingSessions,
      memo: memo ?? this.memo,
      excludedDates: excludedDates ?? this.excludedDates,
      makeupDates: makeupDates ?? this.makeupDates,
    );
  }

  bool get isValid => startDate.isBefore(endDate);

  int get calculatedTotalSessions {
    final allDates = <DateTime>[];
    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      if (recurringDays.any((day) => current.weekday == _weekdayToInt(day)) &&
          !excludedDates.contains(current)) {
        allDates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    allDates.addAll(makeupDates);
    return allDates.toSet().length;
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'recurringDays': recurringDays.map((d) => weekdayToString(d)).toList(),
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'totalFee': totalFee,
    'totalSessions': totalSessions,
    'remainingSessions': remainingSessions,
    'memo': memo,
    'excludedDates': excludedDates.map((d) => d.toIso8601String()).toList(),
    'makeupDates': makeupDates.map((d) => d.toIso8601String()).toList(),
  };

  factory Lecture.fromJson(Map<String, dynamic> json, {String? id}) {
    return Lecture(
      id: id,
      title: json['title'],
      recurringDays:
          (json['recurringDays'] as List<dynamic>)
              .map((d) => weekdayFromString(d as String))
              .toList(),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      totalFee: json['totalFee'],
      totalSessions: json['totalSessions'],
      remainingSessions: json['remainingSessions'],
      memo: json['memo'],
      excludedDates:
          (json['excludedDates'] as List<dynamic>)
              .map((d) => DateTime.parse(d))
              .toList(),
      makeupDates:
          (json['makeupDates'] as List<dynamic>)
              .map((d) => DateTime.parse(d))
              .toList(),
    );
  }

  int _weekdayToInt(Weekday day) {
    switch (day) {
      case Weekday.mon:
        return DateTime.monday;
      case Weekday.tue:
        return DateTime.tuesday;
      case Weekday.wed:
        return DateTime.wednesday;
      case Weekday.thu:
        return DateTime.thursday;
      case Weekday.fri:
        return DateTime.friday;
      case Weekday.sat:
        return DateTime.saturday;
      case Weekday.sun:
        return DateTime.sunday;
    }
  }

  String weekdayToKorean(Weekday day) {
    switch (day) {
      case Weekday.sun:
        return '일';
      case Weekday.mon:
        return '월';
      case Weekday.tue:
        return '화';
      case Weekday.wed:
        return '수';
      case Weekday.thu:
        return '목';
      case Weekday.fri:
        return '금';
      case Weekday.sat:
        return '토';
    }
  }

  Weekday koreanToWeekday(String value) {
    switch (value) {
      case '일':
        return Weekday.sun;
      case '월':
        return Weekday.mon;
      case '화':
        return Weekday.tue;
      case '수':
        return Weekday.wed;
      case '목':
        return Weekday.thu;
      case '금':
        return Weekday.fri;
      case '토':
        return Weekday.sat;
      default:
        throw ArgumentError('Invalid weekday string: $value');
    }
  }

}
