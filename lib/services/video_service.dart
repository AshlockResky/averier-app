import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

class VideoService {
  final _db = FirebaseFirestore.instance;

  Stream<List<VideoModel>> watchFeed() {
    return _db
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VideoModel.fromFirestore(doc.data())).toList());
  }

  Future<void> incrementView(String videoId) async {
    await _db.collection('videos').doc(videoId).update({'views': FieldValue.increment(1)});
  }

  Future<void> toggleLike({required String videoId, required String userId}) async {
    await _db.collection('videos').doc(videoId).update({'likes': FieldValue.increment(1)});
  }
}