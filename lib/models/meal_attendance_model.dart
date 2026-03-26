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
    return MealStudent(
      id: json['id'],
      namaSiswa: json['nama_siswa'],
      nomorInduk: json['nomor_induk'].toString(),
      kelas: json['kelas'] ?? '-',
      roomName: json['room_name'] ?? '-',
      attendanceId: json['attendance_id'] != null ? int.tryParse(json['attendance_id'].toString()) : null,
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
