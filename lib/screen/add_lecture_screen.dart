import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:refund_class/model/lecture_model.dart';

import '../provider/lecture_repository_provider.dart';
import '../widget/recurring_date_selector.dart';

const weekdayOrder = [
  Weekday.sun,
  Weekday.mon,
  Weekday.tue,
  Weekday.wed,
  Weekday.thu,
  Weekday.fri,
  Weekday.sat,
];

class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeRange({required this.start, required this.end});

  String format() {
    String formatTime(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${formatTime(start)}~${formatTime(end)}';
  }
}

class AddLectureScreen extends ConsumerStatefulWidget {
  const AddLectureScreen({super.key});

  @override
  ConsumerState createState() => _AddLectureScreenState();
}

class _AddLectureScreenState extends ConsumerState<AddLectureScreen> {
  final _textController = TextEditingController();
  final _feeTextController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _titleHasError = false;
  bool _feeHasError = false;
  bool _memoHassError = false;
  final List<Map<String, dynamic>> _weekdays = [
    {'day': Weekday.sun, 'label': '일'},
    {'day': Weekday.mon, 'label': '월'},
    {'day': Weekday.tue, 'label': '화'},
    {'day': Weekday.wed, 'label': '수'},
    {'day': Weekday.thu, 'label': '목'},
    {'day': Weekday.fri, 'label': '금'},
    {'day': Weekday.sat, 'label': '토'},
  ];
  List<Weekday> _recurringDays = [];
  Map<Weekday, TimeRange> _weekdayTimes = {};
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  List<DateTime> excluded = [];
  List<DateTime> makeup = [];
  String _memo = '';

  @override
  void dispose() {
    _textController.dispose();
    _feeTextController.dispose();
    super.dispose();
  }

  void _submitLecture() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final sortedRecurringDays = _recurringDays.toList()
      ..sort((a, b) => weekdayOrder.indexOf(a).compareTo(weekdayOrder.indexOf(b)));

    final feeText = _feeTextController.text;
    if (feeText.isEmpty || int.tryParse(feeText) == null) {
      setState(() => _feeHasError = true);
      return;
    }
    final totalFee = int.parse(feeText);

    final sessionDates = <DateTime>[];
    DateTime current = startDate;
    while (!current.isAfter(endDate.add(Duration(days: 1)))) {
      if (_recurringDays.any((d) => current.weekday == _weekdayToInt(d)) &&
          !excluded.contains(DateTime(current.year, current.month, current.day))) {
        sessionDates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }
    final int totalSessions = sessionDates.length;
    final int remainingSessions = totalSessions;


    final timeSlots = _weekdayTimes.entries.map((e) {
      return LectureTimeSlot(
        day: e.key,
        startTime: e.value.start,
        endTime: e.value.end,
      );
    }).toList();

    final newLecture = Lecture(
      title: _textController.text,
      recurringDays: sortedRecurringDays,
      timeSlots: timeSlots,
      startDate: startDate,
      endDate: endDate,
      totalFee: totalFee,
      totalSessions: totalSessions,
      remainingSessions: remainingSessions,
      memo: _memo,
      excludedDates: excluded,
      makeupDates: [],
    );

    ref.read(lectureRepositoryProvider).addLecture(newLecture);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('강좌가 등록되었습니다'), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('강좌 추가하기'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 15.0),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              _buildTitleAndFeeFields(),
              const SizedBox(height: 50),
              _buildRecurringDays(),
              const SizedBox(height: 20),
              _buildTimeSettings(),
              const SizedBox(height: 50),
              _buildDateSelectors(),
              const SizedBox(height: 50),
              Text('수업일을 확인해주세요',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22.0)),
              RecurringDateSelector(
                startDate: startDate,
                endDate: endDate,
                recurringDays: _recurringDays,
                initialExcludedDates: excluded,
                onChanged: (newExcluded) => setState(() => excluded = newExcluded),
              ),
              const SizedBox(height: 50),
              _buildMemoField(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleAndFeeFields() {
    return Row(
      children: [
        Expanded(
          child: _buildTextField('강좌명', _textController, _titleHasError, (v) {
            if (v == null || v.isEmpty) {
              setState(() => _titleHasError = true);
              return '강좌명을 입력하세요';
            }
            _titleHasError = false;
            return null;
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTextField('수강료', _feeTextController, _feeHasError, (v) {
            if (v == null || v.isEmpty) {
              setState(() => _feeHasError = true);
              return '수강료를 입력하세요';
            } else if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
              setState(() => _feeHasError = true);
              return '숫자만 입력해주세요';
            }
            _feeHasError = false;
            return null;
          }),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, bool hasError, FormFieldValidator<String> validator) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 22.0)),
        const SizedBox(height: 15),
        TextFormField(
          controller: controller,
          decoration: _blueInputDecoration().copyWith(
            fillColor: hasError ? Colors.red[50] : Colors.blue[50],
            hintText: '$label 입력',
          ),
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRecurringDays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('반복 요일', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22.0)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _weekdays.map((item) {
            final day = item['day'] as Weekday;
            final label = item['label'] as String;
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: _DaysInkWell(
                isSelected: _recurringDays.contains(day),
                text: label,
                onTap: () {
                  setState(() {
                    if (_recurringDays.contains(day)) {
                      _recurringDays.remove(day);
                      _weekdayTimes.remove(day);
                    } else {
                      _recurringDays.add(day);
                    }
                  });
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _recurringDays.map((day) {
        final time = _weekdayTimes[day];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              Text(weekdayToKorean(day),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
              const SizedBox(width: 10),
              if (time != null) Text(time.format(), style: const TextStyle(fontSize: 16)),
              const Spacer(),
              ElevatedButton(
                onPressed: () async {
                  final start = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 10, minute: 0),
                  );
                  if (start == null) return;

                  final end = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(hour: start.hour + 1, minute: start.minute),
                  );
                  if (end == null) return;

                  setState(() {
                    _weekdayTimes[day] = TimeRange(start: start, end: end);
                  });
                },
                child: Text(time == null ? '시간 설정하기' : '수정'),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelectors() {
    return Row(
      children: [
        Flexible(
          child: SelectDateColumn(
            title: '시작 날짜',
            date: startDate,
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              setState(() {
                startDate = pickedDate ?? startDate;
              });
            },
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: SelectDateColumn(
            title: '마지막 날짜',
            date: endDate,
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: endDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              setState(() {
                endDate = pickedDate ?? endDate;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMemoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('메모', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22.0)),
        const SizedBox(height: 15),
        TextFormField(
          maxLines: 5,
          decoration: _blueInputDecoration().copyWith(
            fillColor: _memoHassError ? Colors.red[50] : Colors.blue[50],
            hintText: '예: 2025-05-14 휴강 / 2025-06-12 보강',
          ),
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
          validator: (value) {
            if (value != null && value.length > 1000) {
              setState(() => _memoHassError = true);
              return '1000자 이하로 작성해주세요';
            }
            _memoHassError = false;
            return null;
          },
          onChanged: (_) => setState(() {}),
          onSaved: (value) => _memo = value ?? '',
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return InkWell(
      onTap: _submitLecture,
      borderRadius: BorderRadius.circular(5.0),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(10.0),
            child: Text('등록하기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

InputDecoration _blueInputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: Colors.blue[50],
    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
    border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 1.5)),
    errorBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 1.5)),
  );
}

class _DaysInkWell extends StatelessWidget {
  final bool isSelected;
  final String text;
  final VoidCallback onTap;

  const _DaysInkWell({required this.isSelected, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Ink(
        width: 65.0,
        height: 65.0,
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue[600]! : Colors.grey[400]!,
            width: 1.5,
          ),
          shape: BoxShape.circle,
          color: isSelected ? Colors.blue[50] : Colors.white,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.blue[600] : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

class SelectDateColumn extends StatelessWidget {
  final String title;
  final DateTime date;
  final Function() onPressed;

  const SelectDateColumn({
    super.key,
    required this.date,
    required this.onPressed,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22.0),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.blue[50],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('yyyy-MM-dd').format(date),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 20),
                  Icon(Icons.calendar_month, color: Colors.grey[700]),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
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