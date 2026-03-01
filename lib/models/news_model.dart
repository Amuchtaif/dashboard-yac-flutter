class News {
  final int id;
  final String title;
  final String category;
  final String content;
  final String coverPhoto;
  final String authorName;
  final int likes;
  final int views;
  final bool isLiked;
  final String createdAt;

  News({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.coverPhoto,
    required this.authorName,
    required this.likes,
    required this.views,
    required this.isLiked,
    required this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: _asInt(json['id']),
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      coverPhoto: json['image_url']?.toString() ?? '',
      authorName: json['author_name']?.toString() ?? '',
      likes: _asInt(json['likes_count']),
      views: _asInt(json['views_count']),
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  static int _asInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    return int.tryParse(val.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'content': content,
      'image_url': coverPhoto,
      'author_name': authorName,
      'likes_count': likes,
      'views_count': views,
      'is_liked': isLiked,
      'created_at': createdAt,
    };
  }
}
