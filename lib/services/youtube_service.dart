import 'package:http/http.dart' as http;
import '../models/video_model.dart';

class YoutubeService {
  static const String _channelId = 'UCMgqNUO2P9F5HIDDNzxr1Wg';
  static const String _feedUrl =
      'https://www.youtube.com/feeds/videos.xml?channel_id=$_channelId';

  Future<List<VideoModel>> getVideos() async {
    try {
      final response = await http.get(Uri.parse(_feedUrl));

      if (response.statusCode == 200) {
        return _parseXml(response.body);
      } else {
        throw Exception('Failed to load videos');
      }
    } catch (e) {
      throw Exception('Failed to connect to YouTube: $e');
    }
  }

  List<VideoModel> _parseXml(String xml) {
    // Simple Regex parser for XML feed
    // Note: This is a basic parser and might break if XML structure changes significantly.
    // Ideally use 'xml' package if added to dependencies.

    final List<VideoModel> videos = [];

    // Split by <entry> to isolate videos
    final entries = xml.split('<entry>');

    // Skip header (index 0)
    for (var i = 1; i < entries.length; i++) {
      final entry = entries[i];

      final idMatch = RegExp(
        r'<yt:videoId>(.*?)</yt:videoId>',
      ).firstMatch(entry);
      final titleMatch = RegExp(r'<title>(.*?)</title>').firstMatch(entry);
      final publishedMatch = RegExp(
        r'<published>(.*?)</published>',
      ).firstMatch(entry);

      if (idMatch != null && titleMatch != null && publishedMatch != null) {
        final id = idMatch.group(1)!;
        final title = titleMatch.group(1)!;
        final publishedAt = DateTime.parse(publishedMatch.group(1)!);

        videos.add(
          VideoModel(
            id: id,
            title: title,
            folder: '', // RSS doesn't provide duration/folder info easily
            thumbnailUrl: 'https://i.ytimg.com/vi/$id/mqdefault.jpg',
            publishedAt: publishedAt,
          ),
        );
      }
    }

    return videos;
  }
}
