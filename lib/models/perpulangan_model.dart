class PerpulanganStats {
  final int totalAtHome;
  final int izinCount;
  final int sakitCount;
  final int liburCount;

  PerpulanganStats({
    required this.totalAtHome,
    required this.izinCount,
    required this.sakitCount,
    required this.liburCount,
  });

  factory PerpulanganStats.fromJson(Map<String, dynamic> json) {
    return PerpulanganStats(
      totalAtHome: int.tryParse(json['total_at_home']?.toString() ?? '0') ?? 0,
      izinCount: int.tryParse(json['izin_count']?.toString() ?? '0') ?? 0,
      sakitCount: int.tryParse(json['sakit_count']?.toString() ?? '0') ?? 0,
      liburCount: int.tryParse(json['libur_count']?.toString() ?? '0') ?? 0,
    );
  }
}

class PerpulanganPermit {
  final int id;
  final int studentId;
  final String studentName;
  final String category;
  final String reason;
  final String startDate;
  final String endDate;
  final String status;
  final String? asrama;

  PerpulanganPermit({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.category,
    required this.reason,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.asrama,
  });

  factory PerpulanganPermit.fromJson(Map<String, dynamic> json) {
    return PerpulanganPermit(
      id: int.tryParse(json['id']?.toString() ?? 
                   json['permit_id']?.toString() ?? '0') ?? 0,
      studentId: int.tryParse(json['student_id']?.toString() ?? '0') ?? 0,
      studentName: json['student_name'] ?? json['nama_siswa'] ?? 'Santri -',
      category: json['category'] ?? 'Izin',
      reason: json['reason'] ?? json['keterangan'] ?? '-',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? 'Disetujui',
      asrama: json['asrama'] ?? json['room_name'],
    );
  }
}

class PerpulanganStudent {
  final int id;
  final String name;
  final String className;

  PerpulanganStudent({
    required this.id,
    required this.name,
    required this.className,
  });

  factory PerpulanganStudent.fromJson(Map<String, dynamic> json) {
    return PerpulanganStudent(
      id: int.tryParse(json['student_id']?.toString() ?? json['id']?.toString() ?? '0') ?? 0,
      name: json['nama_siswa'] ?? json['name'] ?? 'Santri -',
      className: json['kelas'] ?? json['class_name'] ?? '-',
    );
  }
}

class BoardingHoliday {
  final int id;
  final String name;
  final String startDate;
  final String endDate;
  final String status;

  BoardingHoliday({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory BoardingHoliday.fromJson(Map<String, dynamic> json) {
    return BoardingHoliday(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      status: json['status'] ?? 'Aktif',
    );
  }
}

