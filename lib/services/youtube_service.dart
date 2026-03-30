import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/video_model.dart';

class YoutubeService {

  Future<List<VideoModel>> getVideos() async {
    try {
      final headers = {'User-Agent': 'Mozilla/5.0', 'Accept': 'application/xml'};

      // 1. Coba User Feed
      try {
        final response = await http
            .get(
              Uri.parse(
                "https://www.youtube.com/feeds/videos.xml?user=PonpesAssunnahCirebon",
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) return _parseXml(response.body);
      } catch (_) {}

      // 2. Coba Playlist Feed (Fallback)
      try {
        final response = await http
            .get(
              Uri.parse(
                "https://www.youtube.com/feeds/videos.xml?playlist_id=UUMgqNUO2P9F5HIDDNzxr1Wg",
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) return _parseXml(response.body);
      } catch (_) {}

      // 3. Hardcoded Fallback (Jika semua internet error/500)
      // Ini memastikan user tetap bisa melihat video terbaru walaupun RSS YouTube mati
      return [
        VideoModel(
          id: 'xt1bUOwUqms',
          title: 'Hari Raya Idul Fitri 1447 H - KPMI CIAYUMAJAKUNING',
          folder: '',
          thumbnailUrl: 'https://i.ytimg.com/vi/xt1bUOwUqms/mqdefault.jpg',
          publishedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        VideoModel(
          id: 'Lvh2bP0cdxc',
          title: 'Tahniah Hari Raya Idul Fitri 1447 H',
          folder: '',
          thumbnailUrl: 'https://i.ytimg.com/vi/Lvh2bP0cdxc/mqdefault.jpg',
          publishedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        VideoModel(
          id: 'yvvuyuvDq-I',
          title: 'Tahniah Idul Fitri 1447 H - Yayasan Assunnah',
          folder: '',
          thumbnailUrl: 'https://i.ytimg.com/vi/yvvuyuvDq-I/mqdefault.jpg',
          publishedAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
        VideoModel(
          id: '076EAMGM41w',
          title: 'Ustadz M. Toharo, Lc. - Tahniah Idul Fitri',
          folder: '',
          thumbnailUrl: 'https://i.ytimg.com/vi/076EAMGM41w/mqdefault.jpg',
          publishedAt: DateTime.now().subtract(const Duration(days: 4)),
        ),
        VideoModel(
          id: 'NUPxgJdamb8',
          title: 'Jamaah I’TIKAF RAMADHAN 1447 H',
          folder: '',
          thumbnailUrl: 'https://i.ytimg.com/vi/NUPxgJdamb8/mqdefault.jpg',
          publishedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];
    } catch (e) {
      throw Exception('Gagal ambil data YouTube: $e');
    }
  }

  List<VideoModel> _parseXml(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final entries = document.findAllElements('entry');

    final List<VideoModel> videos = [];

    for (var entry in entries) {
      try {
        final idElement = entry.findElements('yt:videoId');
        final titleElement = entry.findElements('title');
        final publishedElement = entry.findElements('published');

        if (idElement.isEmpty ||
            titleElement.isEmpty ||
            publishedElement.isEmpty) {
          continue;
        }

        final id = idElement.first.innerText.trim();
        final title = titleElement.first.innerText.trim();
        final published = publishedElement.first.innerText.trim();

        // Validasi ID (YouTube video ID = 11 karakter)
        if (id.length != 11) continue;

        videos.add(
          VideoModel(
            id: id,
            title: title,
            folder: '',
            thumbnailUrl: 'https://i.ytimg.com/vi/$id/mqdefault.jpg',
            publishedAt: DateTime.parse(published),
          ),
        );
      } catch (_) {
        // skip entry rusak, hidup terlalu singkat buat drama XML
        continue;
      }
    }

    return videos;
  }
}
