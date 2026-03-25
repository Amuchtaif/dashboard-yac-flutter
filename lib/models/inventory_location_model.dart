class InventoryLocationModel {
  final int id;
  final String name;
  final int? parentId;
  final List<InventoryLocationModel> children;
  final String? description;

  InventoryLocationModel({
    required this.id,
    required this.name,
    this.parentId,
    this.children = const [],
    this.description,
  });

  factory InventoryLocationModel.fromJson(Map<String, dynamic> json) {
    return InventoryLocationModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      parentId: int.tryParse(json['parent_id']?.toString() ?? ''),
      children: (json['children'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map((child) => InventoryLocationModel.fromJson(child))
              .toList() ??
          [],
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'children': children.map((e) => e.toJson()).toList(),
      'description': description,
    };
  }
}
