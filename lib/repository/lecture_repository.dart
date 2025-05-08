import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/lecture_model.dart';

class LectureRepository {
  final _db = FirebaseFirestore.instance;

  Future<void> addLecture(Lecture lecture)  async {
    await _db.collection('lectures').add(lecture.toJson());
  }

  Future<List<Lecture>> getLectures() async {
    final snapshot = await _db.collection('lectures').get();

    return snapshot.docs.map((doc) => Lecture.fromJson(doc.data()).copyWith(id: doc.id)).toList();
  }

  Future<void> deleteLecture(String docId) async {
    await _db.collection('lectures').doc(docId).delete();
  }

  Future<void> updateLecture(String docId, Lecture lecture) async {
    await _db.collection('lectures').doc(docId).update(lecture.toJson());
  }
}