class Staff {
  final int id;
  final String name;
  bool isSelected;

  final String division;
  final String unit;

  Staff({
    required this.id,
    required this.name,
    this.division = '',
    this.unit = '',
    this.isSelected = false,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['full_name'] ?? json['name'] ?? 'No Name',
      division: json['division_name'] ?? json['division'] ?? '',
      unit: json['unit_name'] ?? json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
