class AttendanceActivity {
  final int id;
  final String type; // "Check In" or "Check Out"
  final String timestamp;
  final String status; // "On Time", "Late", etc.

  AttendanceActivity({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.status,
  });

  factory AttendanceActivity.fromJson(Map<String, dynamic> json) {
    return AttendanceActivity(
      id:
          json['id'] is int
              ? json['id']
              : int.tryParse(json['id'].toString()) ?? 0,
      type: json['type'] ?? 'Unknown',
      timestamp: json['timestamp'] ?? '',
      status: json['status'] ?? '-',
    );
  }
}
