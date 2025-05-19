import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:refund_class/model/lecture_model.dart';
import 'package:refund_class/provider/base_time_provider.dart';
import 'package:refund_class/util/calculate_remaining_class_util.dart';

import '../repository/lecture_repository.dart';

class DetailScreen extends ConsumerStatefulWidget {
  final Lecture lecture;

  const DetailScreen({super.key, required this.lecture});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
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

  String formatDate(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[date.weekday % 7];
    final dateStr = '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$dateStr ($weekday)';
  }

  Future<void> _saveLecture() async {
    lecture = lecture.copyWith(memo: _memoController.text);
    await FirebaseFirestore.instance.collection('lectures').doc(lecture.id!).update(lecture.toJson());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장되었습니다.'),backgroundColor: Colors.green,));
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

  Future<void> _deleteLecture() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('강좌 삭제'),
        content: const Text('이 강좌를 정말 삭제하시겠어요? 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LectureRepository().deleteLecture(lecture.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseTime = ref.watch(baseTimeProvider);
    final scheduledDates = getFutureClassDate(lecture, baseTime);
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
          _infoRow('남은 수업 횟수', '${scheduledDates.length}회'),
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
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _deleteLecture,
                child: Ink(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red[200],
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: const Center(
                    child: Text('강좌 삭제하기', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.black)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
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
          ],
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
