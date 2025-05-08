import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refund_class/repository/lecture_repository.dart';

final lectureRepositoryProvider = Provider((ref) => LectureRepository());

final lectureListProvider = FutureProvider((ref) {
  return ref.read(lectureRepositoryProvider).getLectures();
});