class MeetingNote {
  final int? id;
  final int meetingId;
  final int userId;
  final String userName;
  final String type; // usulan, notulen
  final String content;
  final DateTime createdAt;

  MeetingNote({
    this.id,
    required this.meetingId,
    required this.userId,
    required this.userName,
    required this.type,
    required this.content,
    required this.createdAt,
  });

  factory MeetingNote.fromJson(Map<String, dynamic> json) {
    return MeetingNote(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()),
      meetingId: json['meeting_id'] is int ? json['meeting_id'] : int.tryParse(json['meeting_id'].toString()) ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id'].toString()) ?? 0,
      userName: json['user_name'] ?? 'Peserta',
      type: json['type'] ?? 'usulan',
      content: json['content'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'meeting_id': meetingId,
      'user_id': userId,
      'type': type,
      'content': content,
    };
  }
}
