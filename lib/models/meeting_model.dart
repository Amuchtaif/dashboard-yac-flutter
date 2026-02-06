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
  });

  factory Meeting.fromJson(Map<String, dynamic> json) {
    return Meeting(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      title: json['title'] ?? json['agenda'] ?? 'No Title',
      type: json['type'] ?? 'Online',
      link: json['link'],
      location: json['location'],
      date: json['date'] ?? '',
      startTime: json['start_time'] ?? json['time'] ?? '',
      endTime: json['end_time'] ?? '',
      participantIds:
          [], // Placeholder, usually fetched separately or requires complex parsing
      divisionId:
          json['division_id'] is int
              ? json['division_id']
              : (int.tryParse(json['division_id']?.toString() ?? '0') ?? 0),
      creatorId:
          json['created_by'] is int
              ? json['created_by']
              : (int.tryParse(json['created_by']?.toString() ?? '0') ?? 0),
      status: json['status'] ?? 'upcoming',
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
    };
  }
}
