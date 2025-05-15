import 'package:flutter/material.dart';
import 'package:refund_class/model/lecture_model.dart';

class RecurringDateSelector extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;
  final List<Weekday> recurringDays;
  final List<DateTime> initialExcludedDates;
  final void Function(List<DateTime> excluded) onChanged;

  const RecurringDateSelector({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.recurringDays,
    this.initialExcludedDates = const [],
    required this.onChanged,
  });

  @override
  State<RecurringDateSelector> createState() => _RecurringDateSelectorState();
}

class _RecurringDateSelectorState extends State<RecurringDateSelector> {
  late Set<DateTime> _excludedDates;

  List<DateTime> get _recurringDates {
    List<DateTime> result = [];
    DateTime current = widget.startDate;
    while (!current.isAfter(widget.endDate)) {
      if (widget.recurringDays.any((day) => current.weekday == _weekdayToInt(day))) {
        result.add(DateTime(current.year, current.month, current.day)); // normalize
      }
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _excludedDates = widget.initialExcludedDates
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
  }

  int _weekdayToInt(Weekday day) {
    return {
      Weekday.mon: DateTime.monday,
      Weekday.tue: DateTime.tuesday,
      Weekday.wed: DateTime.wednesday,
      Weekday.thu: DateTime.thursday,
      Weekday.fri: DateTime.friday,
      Weekday.sat: DateTime.saturday,
      Weekday.sun: DateTime.sunday,
    }[day]!;
  }

  void _toggleExcluded(DateTime date) {
    setState(() {
      final normalized = DateTime(date.year, date.month, date.day);
      if (_excludedDates.contains(normalized)) {
        _excludedDates.remove(normalized);
      } else {
        _excludedDates.add(normalized);
      }
      widget.onChanged(_excludedDates.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    final dates = _recurringDates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('반복 날짜 목록 (${dates.length}회 중 ${_excludedDates.length}회 제외)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: dates.length,
          itemBuilder: (context, index) {
            final date = dates[index];
            final isExcluded = _excludedDates.contains(date);

            return ListTile(
              title: Text(
                formatDateWithKoreanWeekday(date),
                style: TextStyle(
                  color: isExcluded ? Colors.grey : Colors.black,
                  decoration: isExcluded ? TextDecoration.lineThrough : null,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Icon(
                isExcluded ? Icons.close : Icons.check,
                color: isExcluded ? Colors.red : Colors.green,
              ),
              onTap: () => _toggleExcluded(date),
            );
          },
        ),
      ],
    );
  }
}

String formatDateWithKoreanWeekday(DateTime date) {
  const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
  final weekday = weekdays[date.weekday % 7];
  final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  return '$dateStr ($weekday)';
}
