class Meeting {
  final int? id;
  final String title;
  final String type; // Online / Offline
  final String? link;
  final String? location;
  final String date;
  final String startTime;
  final String endTime;
  final List<int> participantIds;
  final int divisionId;
  final int creatorId;
  final String status; // upcoming, finished, draft
  final String? qrToken; // Token untuk QR Code absensi
  final String? creatorName; // Nama pembuat rapat
  final String? divisionName; // Nama divisi

  Meeting({
    this.id,
    required this.title,
    required this.type,
    this.link,
    this.location,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.participantIds,
    required this.divisionId,
    required this.creatorId,
    this.status = 'upcoming',
    this.qrToken,
    this.creatorName,
    this.divisionName,
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      title: json['title'] ?? json['agenda'] ?? 'No Title',
      type: json['type'] ?? 'online',
      link: json['link'],
      location: json['location'],
      date: json['date'] ?? json['meeting_date'] ?? '',
      startTime: json['start_time'] ?? json['time'] ?? '',
      endTime: json['end_time'] ?? '',
      participantIds: [],
      divisionId:
          json['division_id'] is int
              ? json['division_id']
              : (int.tryParse(json['division_id']?.toString() ?? '0') ?? 0),
      creatorId:
          json['created_by'] is int
              ? json['created_by']
              : (int.tryParse(json['created_by']?.toString() ?? '0') ?? 0),
      status: json['status'] ?? 'upcoming',
      qrToken: json['qr_token'],
      creatorName: json['creator_name'],
      divisionName: json['division_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'type': type,
      'link': link,
      'location': location,
      'date': date,
      'start_time': startTime,
      'end_time': endTime,
      'participants': participantIds,
      'division_id': divisionId,
      'created_by': creatorId,
      'status': status,
      'qr_token': qrToken,
    };
  }

  /// Format tanggal ke format Indonesia (Senin, 24 Okt 2023)
  String get formattedDate {
    try {
      final parsed = DateTime.parse(date);
      final days = [
        'Minggu',
        'Senin',
        'Selasa',
        'Rabu',
        'Kamis',
        'Jumat',
        'Sabtu',
      ];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${days[parsed.weekday % 7]}, ${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
    } catch (_) {
      return date;
    }
  }

  /// Format waktu ke format HH:mm - HH:mm WIB
  String get formattedTime {
    final start = startTime.length >= 5 ? startTime.substring(0, 5) : startTime;
    final end = endTime.length >= 5 ? endTime.substring(0, 5) : endTime;
    return '$start - $end WIB';
  }
}
