import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refund_class/repository/lecture_repository.dart';

import '../model/lecture_model.dart';
import '../util/calculate_remaining_class_util.dart';
import 'base_time_provider.dart';

final lectureRepositoryProvider = Provider((ref) => LectureRepository());

final lectureListProvider = StreamProvider<List<Lecture>>((ref) async* {
  final repository = ref.read(lectureRepositoryProvider);
  final baseTime = ref.watch(baseTimeProvider);

  await for (final lectures in repository.getLecturesStream()) {
    for (final lecture in lectures) {
      final calculated = getFutureClassDate(lecture, baseTime).length;
      if (lecture.remainingSessions != calculated) {
        final updated = lecture.copyWith(remainingSessions: calculated);
        await repository.updateLecture(lecture.id!, updated);
      }
    }
    yield lectures;
  }
});