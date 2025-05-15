// 전체 DetailScreen.dart (강의 시간 infoRow로 표시됨)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:refund_class/model/lecture_model.dart';
import 'package:refund_class/util/calculate_remaining_class_util.dart';

class DetailScreen extends StatefulWidget {
  final Lecture lecture;

  const DetailScreen({super.key, required this.lecture});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Lecture lecture;
  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    lecture = widget.lecture;
    _memoController = TextEditingController(text: lecture.memo);
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  String formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> getScheduledDates(Lecture lecture) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = lecture.startDate;
    final end = lecture.endDate;
    final recurringWeekdays = lecture.recurringDays.map(weekdayToInt).toSet();

    final scheduled = <DateTime>[];

    for (var date = start; !date.isAfter(end); date = date.add(Duration(days: 1))) {
      final d = normalize(date);
      final isAfterNow = d.isAfter(today) || (d.isAtSameMomentAs(today) && _isTimeSlotFuture(d));
      if (isAfterNow &&
          recurringWeekdays.contains(date.weekday) &&
          !lecture.excludedDates.map(normalize).contains(d) &&
          !lecture.makeupDates.map(normalize).contains(d)) {
        scheduled.add(d);
      }
    }

    return scheduled;
  }

  bool _isTimeSlotFuture(DateTime date) {
    final now = TimeOfDay.now();
    final day = Weekday.values[date.weekday % 7];
    final slot = lecture.timeSlots.firstWhere(
          (s) => s.day == day,
      orElse: () => LectureTimeSlot(
        day: day,
        startTime: const TimeOfDay(hour: 0, minute: 0),
        endTime: const TimeOfDay(hour: 0, minute: 0),
      ),
    );
    return slot.startTime.hour > now.hour ||
        (slot.startTime.hour == now.hour && slot.startTime.minute > now.minute);
  }

  Future<void> _saveLecture() async {
    lecture = lecture.copyWith(memo: _memoController.text);
    await FirebaseFirestore.instance.collection('lectures').doc(lecture.id!).update(lecture.toJson());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다.')));
    Navigator.of(context).pop();
  }

  void _excludeDate(DateTime date) {
    setState(() {
      lecture = lecture.copyWith(
        excludedDates: [...lecture.excludedDates, normalize(date)],
      );
    });
  }

  void _restoreExcludedDate(DateTime date) {
    setState(() {
      lecture = lecture.copyWith(
        excludedDates: lecture.excludedDates.where((d) => normalize(d) != normalize(date)).toList(),
      );
    });
  }

  void _removeMakeupDate(DateTime date) {
    setState(() {
      lecture = lecture.copyWith(
        makeupDates: lecture.makeupDates.where((d) => normalize(d) != normalize(date)).toList(),
      );
    });
  }

  void _addMakeupDate(DateTime date) {
    if (date.isBefore(lecture.startDate) || date.isAfter(lecture.endDate)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('보강 날짜는 강의 기간 안에 있어야 해요.')));
      return;
    }
    setState(() {
      final d = normalize(date);
      if (!lecture.makeupDates.map(normalize).contains(d)) {
        lecture = lecture.copyWith(makeupDates: [...lecture.makeupDates, d]);
      }
    });
  }

  Future<void> _pickMakeupDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: lecture.startDate,
      lastDate: lecture.endDate,
    );
    if (picked != null) {
      _addMakeupDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledDates = getScheduledDates(lecture);
    final remaining = calculateRemainingClasses(lecture);
    final timeInfo = lecture.timeSlots.map((t) =>
    '${weekdayToKorean(t.day)} ${t.startTime.format(context)}~${t.endTime.format(context)}'
    ).join(', ');

    return Scaffold(
      appBar: AppBar(
        title: Text(lecture.title),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('📝 강의 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          _infoRow('강의명', lecture.title),
          _infoRow('시작일', formatDate(lecture.startDate)),
          _infoRow('종료일', formatDate(lecture.endDate)),
          _infoRow('반복 요일', lecture.recurringDays.map(weekdayToKorean).join(', ')),
          if (lecture.timeSlots.isNotEmpty) _infoRow('강의 시간', timeInfo),
          _infoRow('총 금액', '${lecture.totalFee}원'),
          _infoRow('총 횟수', '${lecture.totalSessions}회'),
          _infoRow('메모', lecture.memo),
          _infoRow('남은 수업 횟수', '${remaining.length}회'),
          const SizedBox(height: 20),
          const Divider(),

          Text('📅 남은 수업 날짜', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...scheduledDates.map((d) => ListTile(
            title: Text(formatDate(d), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _excludeDate(d),
              tooltip: '제외',
            ),
          )),
          if (scheduledDates.isEmpty)
            const Text('남은 수업이 없습니다.', style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 20),
          const Divider(),

          Text('❌ 제외된 날짜 (복구 가능)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          ...lecture.excludedDates.map((d) => ListTile(
            title: Text(formatDate(d), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => _restoreExcludedDate(d),
              tooltip: '복구',
            ),
          )),
          if (lecture.excludedDates.isEmpty)
            const Text('제외된 날짜가 없습니다.', style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 20),
          const Divider(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🩹 보강 날짜', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ElevatedButton.icon(
                onPressed: _pickMakeupDate,
                icon: const Icon(Icons.add),
                label: const Text('보강 추가'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lecture.makeupDates.map((d) => ListTile(
            title: Text(formatDate(d), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              tooltip: '보강 삭제',
              onPressed: () => _removeMakeupDate(d),
            ),
          )),
          if (lecture.makeupDates.isEmpty)
            const Text('보강 날짜가 없습니다.', style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 20),
          const Divider(),

          Text('📝 메모 수정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          TextField(
            controller: _memoController,
            maxLines: 5,
            decoration: _blueInputDecoration().copyWith(
              fillColor: Colors.blue[50],
              hintText: '예: 2025-05-14 휴강 / 2025-06-12 보강',
              hintStyle: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: _saveLecture,
          child: Ink(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue[300],
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: const Center(
              child: Text('저장하기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

InputDecoration _blueInputDecoration() {
  return InputDecoration(
    filled: true,
    fillColor: Colors.blue[50],
    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15),
    border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 1.5)),
    errorBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.red, width: 1.5)),
  );
}
