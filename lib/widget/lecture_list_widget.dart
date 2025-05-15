import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refund_class/model/lecture_model.dart';
import 'package:refund_class/provider/lecture_repository_provider.dart';
import 'package:refund_class/provider/won_formatter_provider.dart';

class LectureListWidget extends ConsumerWidget {
  const LectureListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectureAsync = ref.watch(lectureListProvider);
    final formatter = ref.watch(currentFormatterProvider);

    return lectureAsync.when(
      data: (lectures) {
        return ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: lectures.length,
          itemBuilder: (context, index) {
            final lecture = lectures[index];
            final unitPrice = ((lecture.totalFee / lecture.totalSessions)/10).round() * 10;
            return LectureListInkWell(
              title: lecture.title,
              koreanWeekday:
                  lecture.recurringDays.map(weekdayToKorean).toList(),
              formattedTotalFee: formatter.format(lecture.totalFee),
              totalSessions: lecture.totalSessions,
              remainingSessions: lecture.remainingSessions,
              formattedUnitPrice: formatter.format(unitPrice),
              formattedRefundPrice: formatter.format(
                lecture.remainingSessions * unitPrice,
              ),
              onTap: () {},
            );
          },
          separatorBuilder: (_, _) => const Divider(),
        );
      },
      error: (err, _) => Center(child: Text('오류발생: $err')),
      loading: () => Center(child: const CircularProgressIndicator()),
    );
  }
}

class LectureListInkWell extends StatelessWidget {
  final String title;
  final List<String> koreanWeekday;
  final String formattedTotalFee;
  final int totalSessions;
  final int remainingSessions;
  final String formattedUnitPrice;
  final String formattedRefundPrice;
  final Function() onTap;

  const LectureListInkWell({
    super.key,
    required this.title,
    required this.koreanWeekday,
    required this.formattedTotalFee,
    required this.totalSessions,
    required this.remainingSessions,
    required this.formattedUnitPrice,
    required this.formattedRefundPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  koreanWeekday.join(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  formattedTotalFee,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  totalSessions.toString(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  remainingSessions.toString(),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  formattedUnitPrice,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  formattedRefundPrice,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
