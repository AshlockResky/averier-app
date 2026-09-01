import 'package:cloud_firestore/cloud_firestore.dart';

enum VideoStatus {
  active,
  banned,
  processing;

  String toJson() => name;

  static VideoStatus fromJson(String? value) {
    return VideoStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => VideoStatus.active,
    );
  }
}

class VideoModel {
  final String id;
  final String creatorId;
  final String creatorUsername;
  final String? creatorPhotoUrl;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int views;
  final int likes;
  final int comments;
  final double adRevenueGenerated;
  final bool isEligibleToEarn;
  final VideoStatus status;
  final DateTime createdAt;

  const VideoModel({
    required this.id,
    required this.creatorId,
    required this.creatorUsername,
    this.creatorPhotoUrl,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.views,
    required this.likes,
    required this.comments,
    required this.adRevenueGenerated,
    required this.isEligibleToEarn,
    this.status = VideoStatus.active,
    required this.createdAt,
  });

  // ====================== GETTERS ======================

  /// Creator gets 50% of the ad revenue
  double get creatorEarnings => adRevenueGenerated * 0.5;

  /// Progress toward 5,000 views (0.0 → 1.0)
  double get progressToPayout => (views / 5000).clamp(0.0, 1.0);

  /// Nice text: "4,200 / 5,000 views"
  String get viewsProgressText {
    final current = views.clamp(0, 5000);
    return '$current / 5,000 views';
  }

  // ====================== FROM FIRESTORE ======================
  factory VideoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return VideoModel(
      id: doc.id,
      creatorId: data['creatorId'] as String? ?? '',
      creatorUsername: data['creatorUsername'] as String? ?? '',
      creatorPhotoUrl: data['creatorPhotoUrl'] as String?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      videoUrl: data['videoUrl'] as String? ?? '',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      views: (data['views'] as num?)?.toInt() ?? 0,
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      comments: (data['comments'] as num?)?.toInt() ?? 0,
      adRevenueGenerated: (data['adRevenueGenerated'] as num?)?.toDouble() ?? 0.0,
      isEligibleToEarn: data['isEligibleToEarn'] as bool? ?? false,
      status: VideoStatus.fromJson(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ====================== TO FIRESTORE ======================
  Map<String, dynamic> toFirestore() {
    return {
      'creatorId': creatorId,
      'creatorUsername': creatorUsername,
      'creatorPhotoUrl': creatorPhotoUrl,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'views': views,
      'likes': likes,
      'comments': comments,
      'adRevenueGenerated': adRevenueGenerated,
      'isEligibleToEarn': isEligibleToEarn,
      'status': status.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // ====================== COPY WITH ======================
  VideoModel copyWith({
    String? id,
    String? creatorId,
    String? creatorUsername,
    String? creatorPhotoUrl,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnailUrl,
    int? views,
    int? likes,
    int? comments,
    double? adRevenueGenerated,
    bool? isEligibleToEarn,
    VideoStatus? status,
    DateTime? createdAt,
  }) {
    return VideoModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      creatorPhotoUrl: creatorPhotoUrl ?? this.creatorPhotoUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      adRevenueGenerated: adRevenueGenerated ?? this.adRevenueGenerated,
      isEligibleToEarn: isEligibleToEarn ?? this.isEligibleToEarn,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
