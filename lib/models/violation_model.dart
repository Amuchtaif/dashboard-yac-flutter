
class Violation {
  final int id;
  final int santriId;
  final String namaSiswa;
  final int kategoriId;
  final String namaKategori;
  final int poin;
  final String deskripsi;
  final String tanggalPelanggaran;
  final String? lokasi;
  final int pelaporId;
  final String? pelaporName;
  final String status;
  final String createdAt;

  Violation({
    required this.id,
    required this.santriId,
    required this.namaSiswa,
    required this.kategoriId,
    required this.namaKategori,
    required this.poin,
    required this.deskripsi,
    required this.tanggalPelanggaran,
    this.lokasi,
    required this.pelaporId,
    this.pelaporName,
    required this.status,
    required this.createdAt,
  });

  factory Violation.fromJson(Map<String, dynamic> json) {
    return Violation(
      id: int.tryParse(json['id'].toString()) ?? 0,
      santriId: int.tryParse(json['santri_id'].toString()) ?? 0,
      namaSiswa: json['nama_siswa'] ?? '',
      kategoriId: int.tryParse(json['kategori_id'].toString()) ?? 0,
      namaKategori: json['nama_kategori'] ?? '',
      poin: int.tryParse(json['poin']?.toString() ?? '0') ?? 0,
      deskripsi: json['deskripsi'] ?? '',
      tanggalPelanggaran: json['tanggal_pelanggaran'] ?? '',
      lokasi: json['lokasi'],
      pelaporId: int.tryParse(json['pelapor']?.toString() ?? '0') ?? 0,
      pelaporName: json['pelapor_name'],
      status: json['status'] ?? 'draft',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ViolationCategory {
  final int id;
  final String namaKategori;
  final int poin;

  ViolationCategory({
    required this.id,
    required this.namaKategori,
    required this.poin,
  });

  factory ViolationCategory.fromJson(Map<String, dynamic> json) {
    return ViolationCategory(
      id: int.tryParse(json['id'].toString()) ?? 0,
      namaKategori: json['nama_kategori'] ?? '',
      poin: int.tryParse(json['poin'].toString()) ?? 0,
    );
  }
}

class ViolationFollowup {
  final int id;
  final int violationId;
  final String tindakan;
  final String? catatan;
  final String tanggalTindakan;
  final String penindakName;
  final String createdAt;

  ViolationFollowup({
    required this.id,
    required this.violationId,
    required this.tindakan,
    this.catatan,
    required this.tanggalTindakan,
    required this.penindakName,
    required this.createdAt,
  });

  factory ViolationFollowup.fromJson(Map<String, dynamic> json) {
    return ViolationFollowup(
      id: int.tryParse(json['id'].toString()) ?? 0,
      violationId: int.tryParse(json['pelanggaran_id'].toString()) ?? 0,
      tindakan: json['tindakan'] ?? '',
      catatan: json['catatan'],
      tanggalTindakan: json['tanggal_tindakan'] ?? '',
      penindakName: json['penindak_name'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ViolationOfficer {
  final int id;
  final int employeeId;
  final String nama;
  final String position;

  ViolationOfficer({
    required this.id,
    required this.employeeId,
    required this.nama,
    required this.position,
  });

  factory ViolationOfficer.fromJson(Map<String, dynamic> json) {
    return ViolationOfficer(
      id: int.tryParse(json['id'].toString()) ?? 0,
      employeeId: int.tryParse(json['employee_id'].toString()) ?? 0,
      nama: json['nama'] ?? '',
      position: json['position_name'] ?? '',
    );
  }
}
