class StaffAttendance {
  final int id;
  final String name;
  final String position;
  final String? photo;
  final String time;
  final String status;
  final String unit;

  StaffAttendance({
    required this.id,
    required this.name,
    required this.position,
    this.photo,
    required this.time,
    required this.status,
    this.unit = '',
  });

  factory StaffAttendance.fromJson(Map<String, dynamic> json) {
    return StaffAttendance(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      position: json['position'] ?? json['position_name'] ?? '',
      photo: json['photo'] ?? json['profile_photo'],
      time: json['time'] ?? '-',
      status: json['status'] ?? 'Alpha',
      unit: json['unit_name'] ?? json['unit'] ?? json['division_name'] ?? '',
    );
  }
}
