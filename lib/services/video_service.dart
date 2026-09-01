  import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_model.dart';

class VideoService {
  final _db = FirebaseFirestore.instance;

  Stream<List<VideoModel>> watchFeed() {
    return _db
        .collection('videos')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => VideoModel.fromFirestore(doc.data())).toList());
  }

  Future<void> incrementView(String videoId) async {
    await _db.collection('videos').doc(videoId).update({
      'views': FieldValue.increment(1),
    });
  }

  Future<void> toggleLike({
    required String videoId,
    required String userId,
  }) async {
    final likeRef = _db
        .collection('videos')
        .doc(videoId)
        .collection('likes')
        .doc(userId);

    final videoRef = _db.collection('videos').doc(videoId);

    await _db.runTransaction((tx) async {
      final likeDoc = await tx.get(likeRef);

      if (likeDoc.exists) {
        // Already liked → unlike
        tx.delete(likeRef);
        tx.update(videoRef, {'likes': FieldValue.increment(-1)});
      } else {
        // Not liked → like
        tx.set(likeRef, {
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        tx.update(videoRef, {'likes': FieldValue.increment(1)});
      }
    });
  }
}
