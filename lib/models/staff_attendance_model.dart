class StaffAttendance {
  final int id;
  final String name;
  final String position;
  final String? photo;
  final String time;
  final String status;

  StaffAttendance({
    required this.id,
    required this.name,
    required this.position,
    this.photo,
    required this.time,
    required this.status,
  });

  factory StaffAttendance.fromJson(Map<String, dynamic> json) {
    return StaffAttendance(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      position: json['position'] ?? '',
      photo: json['photo'],
      time: json['time'] ?? '-',
      status: json['status'] ?? 'Alpha',
    );
  }
}
