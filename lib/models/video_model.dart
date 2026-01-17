class VideoModel {
  final String id;
  final String title;
  final String folder;
  final String thumbnailUrl;
  final DateTime publishedAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.folder,
    required this.thumbnailUrl,
    required this.publishedAt,
  });

  String get timeAgo {
    final difference = DateTime.now().difference(publishedAt);
    if (difference.inDays > 365) {
      return "${(difference.inDays / 365).floor()} tahun yang lalu";
    } else if (difference.inDays > 30) {
      return "${(difference.inDays / 30).floor()} bulan yang lalu";
    } else if (difference.inDays > 0) {
      return "${difference.inDays} hari yang lalu";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} jam yang lalu";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} menit yang lalu";
    } else {
      return "Baru saja";
    }
  }
}
