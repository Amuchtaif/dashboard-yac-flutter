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
  final int unitId; // Added unitId
  final bool canManageNews; // Added canManageNews
  final String nik;
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
    required this.unitId,
    required this.nik,
    required this.profilePhoto,
    this.canManageNews = false,
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
      unitId:
          json['unit_id'] is int
              ? json['unit_id']
              : int.tryParse(json['unit_id']?.toString() ?? '0') ?? 0,
      profilePhoto: json['profile_photo'] ?? '',
      nik: json['nik']?.toString() ?? '',
      canManageNews:
          json['can_manage_news'] == 1 ||
          json['can_manage_news'] == '1' ||
          json['can_manage_news'] == true,
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
      'unit_id': unitId,
      'nik': nik,
      'profile_photo': profilePhoto,
      'can_manage_news': canManageNews ? 1 : 0,
    };
  }
}
