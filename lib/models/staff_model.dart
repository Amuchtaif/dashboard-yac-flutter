class Staff {
  final int id;
  final String name;
  bool isSelected;

  final String division;
  final String unit;
  final String position;

  Staff({
    required this.id,
    required this.name,
    this.division = '',
    this.unit = '',
    this.position = '',
    this.isSelected = false,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name:
          json['full_name'] ??
          json['name'] ??
          json['nama'] ??
          json['nama_lengkap'] ??
          json['displayName'] ??
          'No Name',
      division: json['division_name'] ?? json['division'] ?? '',
      unit: json['unit_name'] ?? json['unit'] ?? '',
      position: json['position_name'] ?? json['position'] ?? json['jabatan'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
