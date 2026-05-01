class MealStudent {
  final int id;
  final String namaSiswa;
  final String nomorInduk;
  final String kelas;
  final String roomName;
  final int? attendanceId;
  final String? checkTime;

  MealStudent({
    required this.id,
    required this.namaSiswa,
    required this.nomorInduk,
    required this.kelas,
    required this.roomName,
    this.attendanceId,
    this.checkTime,
  });

  factory MealStudent.fromJson(Map<String, dynamic> json) {
    // Robust parsing for attendance_id which can be int, string, or boolean
    int? parsedAttendanceId;
    final rawAttendanceId = json['attendance_id'];
    if (rawAttendanceId != null) {
      if (rawAttendanceId is int) {
        parsedAttendanceId = rawAttendanceId;
      } else if (rawAttendanceId is bool) {
        parsedAttendanceId = rawAttendanceId ? 1 : null;
      } else {
        parsedAttendanceId = int.tryParse(rawAttendanceId.toString());
      }
    }

    return MealStudent(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      namaSiswa: json['nama_siswa'] ?? '',
      nomorInduk: json['nomor_induk'].toString(),
      kelas: json['kelas'] ?? '-',
      roomName: json['room_name'] ?? '-',
      attendanceId: parsedAttendanceId,
      checkTime: json['check_time'],
    );
  }
}

class MealStats {
  final int totalServed;
  final int totalQuota;

  MealStats({required this.totalServed, required this.totalQuota});

  factory MealStats.fromJson(Map<String, dynamic> json) {
    return MealStats(
      totalServed: int.tryParse(json['total_served'].toString()) ?? 0,
      totalQuota: int.tryParse(json['total_quota'].toString()) ?? 0,
    );
  }
}
