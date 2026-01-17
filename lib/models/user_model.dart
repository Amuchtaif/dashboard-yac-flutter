class User {
  final int id;
  final String fullName;
  final String email;
  final String unitName;
  final String divisionName;
  final String positionName;
  final String phoneNumber;
  final int positionLevel;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.unitName,
    required this.divisionName,
    required this.positionName,
    required this.phoneNumber,
    required this.positionLevel,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      unitName: json['unit_name'] ?? '',
      divisionName: json['division_name'] ?? '',
      positionName: json['position_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      positionLevel:
          json['position_level'] is int
              ? json['position_level']
              : int.tryParse(json['position_level'].toString()) ?? 99,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'unit_name': unitName,
      'division_name': divisionName,
      'position_name': positionName,
      'phone_number': phoneNumber,
      'position_level': positionLevel,
    };
  }
}
