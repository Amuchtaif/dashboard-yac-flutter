class News {
  final int id;
  final String title;
  final String category;
  final String content;
  final String coverPhoto;
  final String authorName;
  final int likes;
  final String createdAt;

  News({
    required this.id,
    required this.title,
    required this.category,
    required this.content,
    required this.coverPhoto,
    required this.authorName,
    required this.likes,
    required this.createdAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      content: json['content'] ?? '',
      coverPhoto: json['image_url'] ?? '',
      authorName: json['author_name'] ?? '',
      likes:
          json['likes_count'] is int
              ? json['likes_count']
              : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] ?? '',
    );
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
      'created_at': createdAt,
    };
  }
}
