class EmployeeGroup {
  final int id;
  final String groupName;
  final String groupType; // 'dynamic' or 'manual'
  final String description;
  final int isActive;
  final String createdAt;
  final String name;
  final String type;

  EmployeeGroup({
    required this.id,
    required this.groupName,
    required this.groupType,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.name,
    required this.type,
  });

  factory EmployeeGroup.fromJson(Map<String, dynamic> json) {
    return EmployeeGroup(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      groupName: json['group_name'] ?? json['name'] ?? '',
      groupType: json['group_type'] ?? json['type'] ?? 'manual',
      description: json['description'] ?? '',
      isActive: json['is_active'] is int
          ? json['is_active']
          : int.tryParse(json['is_active']?.toString() ?? '1') ?? 1,
      createdAt: json['created_at'] ?? '',
      name: json['name'] ?? json['group_name'] ?? '',
      type: json['type'] ?? json['group_type'] ?? 'manual',
    );
  }
}
