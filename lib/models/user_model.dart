class User {
  final int id;
  final String fullName;
  final String email;
  final String unitName;
  final String divisionName;
  final String positionName;
  final String phoneNumber;
  final String address; // Added address
  final int positionLevel;
  final int divisionId; // Added divisionId

  final String profilePhoto;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.unitName,
    required this.divisionName,
    required this.positionName,
    required this.phoneNumber,
    required this.address,
    required this.positionLevel,
    required this.divisionId,
    required this.profilePhoto,
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
      address: json['address'] ?? '',
      positionLevel:
          json['position_level'] is int
              ? json['position_level']
              : int.tryParse(json['position_level'].toString()) ?? 99,
      divisionId:
          json['division_id'] is int
              ? json['division_id']
              : int.tryParse(json['division_id']?.toString() ?? '0') ?? 0,
      profilePhoto: json['profile_photo'] ?? '',
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
      'address': address,
      'position_level': positionLevel,
      'division_id': divisionId,
      'profile_photo': profilePhoto,
    };
  }
}
