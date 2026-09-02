import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/video_model.dart';
import '../config/constants.dart';

class VideoService {
  final _db = FirebaseFirestore.instance;

  Stream<List<VideoModel>> watchFeed() {
    return _db
        .collection('videos')
        .where('status', isEqualTo: VideoStatus.active.toJson()) // Better than string
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VideoModel.fromFirestore(doc))
            .toList());
  }

  Future<void> incrementView(String videoId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final videoRef = _db.collection('videos').doc(videoId);
    
    // FIXED: Corrected the broken Dart string interpolation format
    final viewRef = _db.collection('videoViews').doc('${videoId}_${user.uid}');

    await _db.runTransaction((tx) async {
      final viewDoc = await tx.get(viewRef);
      if (viewDoc.exists) return; // Already counted

      tx.set(viewRef, {
        'videoId': videoId,
        'userId': user.uid,
        'viewedAt': FieldValue.serverTimestamp(),
      });

      final videoDoc = await tx.get(videoRef);
      if (!videoDoc.exists) return;

      final data = videoDoc.data()!;
      final currentViews = (data['views'] ?? 0) as int;
      final isAlreadyEligible = data['isEligibleToEarn'] ?? false;

      final nextViews = currentViews + 1;
      final Map<String, dynamic> videoUpdates = {
        'views': FieldValue.increment(1),
      };

      // Mark eligible at 5,000 views safely using structural transaction logic
      if (!isAlreadyEligible && nextViews >= AppConstants.minViewsToEarn) {
        videoUpdates['isEligibleToEarn'] = true;
      }

      tx.update(videoRef, videoUpdates);
    });
  }

  Future<void> toggleLike({
    required String videoId,
    required String userId,
  }) async {
    final likeRef = _db.collection('videoLikes').doc('${videoId}_$userId');
    final videoRef = _db.collection('videos').doc(videoId);

    await _db.runTransaction((tx) async {
      final likeDoc = await tx.get(likeRef);

      if (likeDoc.exists) {
        tx.delete(likeRef);
        tx.update(videoRef, {'likes': FieldValue.increment(-1)});
      } else {
        tx.set(likeRef, {
          'videoId': videoId,
          'userId': userId,
          'likedAt': FieldValue.serverTimestamp(),
        });
        tx.update(videoRef, {'likes': FieldValue.increment(1)});
      }
    });
  }

  /// ONLY call this after AdMob pays you
  /// 🛑 SECURITY WARNING: This method is highly vulnerable to client-side balance spoofing.
  /// Move this logic to Firebase Cloud Functions for production environments.
  Future<void> creditCreatorFromAdRevenue({
    required String videoId,
    required double realAdRevenue,
  }) async {
    final videoRef = _db.collection('videos').doc(videoId);

    await _db.runTransaction((tx) async {
      final videoDoc = await tx.get(videoRef);
      if (!videoDoc.exists) throw Exception('Video not found');

      final data = videoDoc.data()!;
      final creatorId = data['creatorId'] as String?;
      final isEligible = data['isEligibleToEarn'] ?? false;

      if (!isEligible) throw Exception('Video is not eligible yet');
      if (creatorId == null) throw Exception('Creator ID missing');

      // Use increment so it stacks if called multiple times
      tx.update(videoRef, {
        'adRevenueGenerated': FieldValue.increment(realAdRevenue),
      });

      final creatorShare = realAdRevenue * AppConstants.creatorRevenueShare;

      final userRef = _db.collection('users').doc(creatorId);
      tx.update(userRef, {
        'balance': FieldValue.increment(creatorShare),
        'totalEarned': FieldValue.increment(creatorShare),
      });
    });
  }
}
