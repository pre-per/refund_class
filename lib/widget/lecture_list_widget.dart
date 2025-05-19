import 'package:refund_class/provider/search_query_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refund_class/model/lecture_model.dart';
import 'package:refund_class/provider/lecture_repository_provider.dart';
import 'package:refund_class/provider/won_formatter_provider.dart';
import 'package:refund_class/screen/detail_screen.dart';

class LectureListWidget extends ConsumerWidget {
  const LectureListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lectureAsync = ref.watch(lectureListProvider);
    final formatter = ref.watch(currentFormatterProvider);
    final query = ref.watch(lectureSearchQueryProvider).toLowerCase();

    return lectureAsync.when(
      data: (lectures) {
        final filteredLectures = lectures.where((lecture) {
          return lecture.title.toLowerCase().contains(query);
        }).toList();

        return ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: filteredLectures.length,
          itemBuilder: (context, index) {
            final lecture = filteredLectures[index];
            final unitPrice =
            (lecture.totalFee / lecture.totalSessions).round();

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
              formattedFinalPrice: formatter.format((lecture.remainingSessions * unitPrice / 10).round() * 10),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailScreen(lecture: lecture)));
              },
            );
          },
          separatorBuilder: (_, __) => const Divider(),
        );
      },
      error: (err, _) => Center(child: Text('오류발생: $err')),
      loading: () => const Center(child: CircularProgressIndicator()),
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
  final String formattedFinalPrice;
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
    required this.onTap, required this.formattedFinalPrice,
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
              flex: 1,
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
            Expanded(
              flex: 2,
              child: Center(
                child: Text(
                  formattedFinalPrice,
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
