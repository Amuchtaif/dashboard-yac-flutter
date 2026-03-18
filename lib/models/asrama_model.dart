class Asrama {
  final int id;
  final String nama;
  final String gedung;
  final int totalSantri;
  final int hadir;
  final bool sudahAbsen;

  Asrama({
    required this.id,
    required this.nama,
    required this.gedung,
    required this.totalSantri,
    required this.hadir,
    required this.sudahAbsen,
  });

  factory Asrama.fromJson(Map<String, dynamic> json) {
    int total = int.tryParse(json['total_students']?.toString() ?? 
                 json['total_santri']?.toString() ?? '0') ?? 0;
    int filled = int.tryParse(json['attended_count']?.toString() ?? 
                  json['hadir']?.toString() ?? '0') ?? 0;
    
    // Prioritas flag dari server, fallback ke jumlah hitung
    bool isCompleted = json['is_filled'] == 1 || 
                       json['is_filled'] == '1' || 
                       json['sudah_absen'] == true ||
                       (json['is_filled'] != null && json['is_filled'] != 0);

    return Asrama(
      id: int.tryParse(json['room_id']?.toString() ?? 
                   json['asrama_id']?.toString() ?? 
                   json['id_asrama']?.toString() ?? 
                   json['id_kamar']?.toString() ?? 
                   json['kamar_id']?.toString() ?? 
                   json['id']?.toString() ?? '0') ?? 0,
      nama: json['room_name'] ?? json['name'] ?? json['nama'] ?? 'Kamar Tidak Diketahui',
      gedung: json['building_name'] ?? json['building'] ?? json['gedung'] ?? '',
      totalSantri: total,
      hadir: filled,
      sudahAbsen: isCompleted,
    );
  }
}

class SantriAsrama {
  final int id;
  final String nama;
  final String kelas;
  String status; // Hadir, Izin, Sakit, Alfa
  String? keterangan;

  SantriAsrama({
    required this.id,
    required this.nama,
    required this.kelas,
    this.status = '',
    this.keterangan,
  });

  factory SantriAsrama.fromJson(Map<String, dynamic> json) {
    return SantriAsrama(
      id: int.tryParse(json['id']?.toString() ?? 
                   json['student_id']?.toString() ?? 
                   json['id_siswa']?.toString() ?? 
                   json['id_santri']?.toString() ?? 
                   json['siswa_id']?.toString() ?? 
                   json['santri_id']?.toString() ?? 
                   json['user_id']?.toString() ?? 
                   json['id_user']?.toString() ?? 
                   json['master_siswa_id']?.toString() ?? '0') ?? 0,
      nama: json['nama_siswa'] ?? json['nama_santri'] ?? json['name'] ?? 'Santri -',
      kelas: json['kelas'] ?? json['class_name'] ?? 'Kelas -',
      status: json['status'] ?? json['absensi_status'] ?? '', 
      keterangan: json['notes'] ?? json['keterangan'] ?? json['keterangan_absen'],
    );
  }
}
