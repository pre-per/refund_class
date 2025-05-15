import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refund_class/model/lecture_model.dart';
import 'package:intl/intl.dart';

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
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  List<DateTime> excluded = [];
  List<DateTime> makeup = [];
  String _memo = '';

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _textController.dispose();
    _feeTextController.dispose();
  }

  void _submitLecture() {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    final sortedRecurringDays = _recurringDays.toList()
      ..sort((a, b) => weekdayOrder.indexOf(a).compareTo(weekdayOrder.indexOf(b)));

    // 수강료 텍스트필드에서 값 가져오기
    final feeText = _feeTextController.text;
    if (feeText.isEmpty || int.tryParse(feeText) == null) {
      setState(() {
        _feeHasError = true;
      });
      return;
    }

    final totalFee = int.parse(feeText);

    // 수업 날짜 계산
    final sessionDates = <DateTime>[];
    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      if (_recurringDays.any((d) => current.weekday == _weekdayToInt(d)) &&
          !excluded.contains(DateTime(current.year, current.month, current.day))) {
        sessionDates.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    final totalSessions = sessionDates.length;
    final remainingSessions = totalSessions;

    final newLecture = Lecture(
      title: _textController.text,
      recurringDays: sortedRecurringDays,
      startDate: startDate,
      endDate: endDate,
      totalFee: totalFee,
      totalSessions: totalSessions,
      remainingSessions: remainingSessions,
      memo: _memo,
      excludedDates: excluded,
      makeupDates: [],
    );

    // Firebase에 저장
    ref.read(lectureRepositoryProvider).addLecture(newLecture);

    // 등록 완료 후 홈으로 이동
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('강좌가 등록되었습니다'), backgroundColor: Colors.green,),
    );

    Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('강좌 추가하기'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.close),
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
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '강좌명',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 22.0,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _textController,
                          decoration: _blueInputDecoration().copyWith(
                            fillColor:
                                _titleHasError
                                    ? Colors.red[50]
                                    : Colors.blue[50],
                            hintText: '강좌명을 입력하세요',
                            hintStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _titleHasError = true;
                              });
                              return '비밀번호를 입력하세요';
                            }
                            _titleHasError = false;
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '수강료',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 22.0,
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _feeTextController,
                          decoration: _blueInputDecoration().copyWith(
                            fillColor:
                                _feeHasError ? Colors.red[50] : Colors.blue[50],
                            hintText: '수강료를 입력하세요',
                            hintStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              setState(() {
                                _feeHasError = true;
                              });
                              return '비밀번호를 입력하세요';
                            } else if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              setState(() {
                                _feeHasError = true;
                              });
                              return '숫자만 입력해주세요';
                            }
                            _feeHasError = false;
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Text(
                '반복 요일',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22.0),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    _weekdays.map((item) {
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
                              } else {
                                _recurringDays.add(day);
                              }
                            });
                          },
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 50),
              Row(
                children: [
                  Flexible(
                    flex: 1,
                    child: SelectDateColumn(
                      title: '시작 날짜',
                      date: startDate,
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2000, 1, 1),
                          lastDate: DateTime(2100, 1, 1),
                        );
                        setState(() {
                          startDate = pickedDate ?? startDate;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    flex: 1,
                    child: SelectDateColumn(
                      title: '마지막 날짜',
                      date: endDate,
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: endDate,
                          firstDate: DateTime(2000, 1, 1),
                          lastDate: DateTime(2100, 1, 1),
                        );
                        setState(() {
                          endDate = pickedDate ?? endDate;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Text(
                '수업일을 확인해주세요',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22.0),
              ),
              RecurringDateSelector(
                startDate: startDate,
                endDate: endDate,
                recurringDays: _recurringDays,
                initialExcludedDates: excluded,
                onChanged: (List<DateTime> newExcluded) {
                  setState(() {
                    excluded = newExcluded;
                  });
                },
              ),

              const SizedBox(height: 50),
              Text(
                '메모',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 22.0),
              ),
              const SizedBox(height: 15),
              TextFormField(
                maxLines: 5,
                decoration: _blueInputDecoration().copyWith(
                  fillColor: _memoHassError ? Colors.red[50] : Colors.blue[50],
                  hintText: '예: 2025-05-14 휴강 / 2025-06-12 보강',
                  hintStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                validator: (value) {
                  if (value != null && value.length > 1000) {
                    setState(() {
                      _memoHassError = true;
                    });
                    return '1000자 이하로 작성해주세요';
                  }
                  _memoHassError = false;
                  return null;
                },
                onChanged: (value) {
                  setState(() {}); // 추후 필요 시 로직 삽입
                },
                onSaved: (value) {
                  _memo = value ?? '';
                },
              ),

              const SizedBox(height: 30),
              InkWell(
                onTap: _submitLecture,
                borderRadius: BorderRadius.circular(5.0),
                child: Ink(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text('등록하기', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
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
    border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.transparent),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.blue, width: 1.5),
    ),
    errorBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.red, width: 1.5),
    ),
  );
}

class _DaysInkWell extends StatelessWidget {
  final bool isSelected;
  final String text;
  final VoidCallback onTap;

  const _DaysInkWell({
    super.key,
    required this.isSelected,
    required this.text,
    required this.onTap,
  });

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

// --------------------------
// 날짜 선택 위젯
// --------------------------

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
