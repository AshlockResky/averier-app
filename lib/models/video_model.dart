class VideoModel {
  final String id;
  final String creatorId;
  final String creatorUsername;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnailUrl;
  final int views;
  final int likes;
  final int comments;
  final double adRevenueGenerated;
  final bool isEligibleToEarn;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.creatorId,
    required this.creatorUsername,
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.views,
    required this.likes,
    required this.comments,
    required this.adRevenueGenerated,
    required this.isEligibleToEarn,
    required this.createdAt,
  });

  factory VideoModel.fromFirestore(Map<String, dynamic> data) {
    return VideoModel(
      id: data['id'] ?? '',
      creatorId: data['creatorId'] ?? '',
      creatorUsername: data['creatorUsername'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoUrl: data['videoUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      comments: data['comments'] ?? 0,
      adRevenueGenerated: (data['adRevenueGenerated'] ?? 0.0).toDouble(),
      isEligibleToEarn: data['isEligibleToEarn'] ?? false,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}