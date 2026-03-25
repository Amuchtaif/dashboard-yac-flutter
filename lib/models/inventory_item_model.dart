import '../core/api_constants.dart';

class InventoryItemModel {
  final int id;
  final String name;
  final String? code;
  final String? description;
  final int locationId;
  final String? locationBreadcrumb;
  final int quantity;
  final String? unit;
  final String? condition;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryItemModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    required this.locationId,
    this.locationBreadcrumb,
    required this.quantity,
    this.unit,
    this.condition,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) {
    String? toStringSafe(dynamic val) {
      if (val == null) return null;
      String s = val.toString();
      return (s == 'null' || s.isEmpty) ? null : s;
    }

    return InventoryItemModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] ?? json['item_name'] ?? json['nama_barang'] ?? '').toString(),
      code: toStringSafe(json['item_code'] ?? json['code'] ?? json['kode_barang']),
      description: toStringSafe(json['description'] ?? json['keterangan'] ?? json['deskripsi_barang']),
      locationId: int.tryParse((json['location_id'] ?? json['id_lokasi'])?.toString() ?? '0') ?? 0,
      locationBreadcrumb: toStringSafe(json['location_breadcrumb'] ?? json['breadcrumb_lokasi']),
      quantity: int.tryParse((json['qty'] ?? json['quantity'] ?? json['jumlah_barang'])?.toString() ?? '0') ?? 0,
      unit: toStringSafe(json['item_unit'] ?? json['unit'] ?? json['satuan_barang']),
      condition: toStringSafe(json['item_condition'] ?? json['condition'] ?? json['kondisi_barang']),
      imageUrl: ApiConstants.getInventoryPhotoUrl(
        toStringSafe(json['item_photo'] ?? json['foto_barang'] ?? json['image_url']),
      ),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'item_code': code,
      'description': description,
      'location_id': locationId,
      'location_breadcrumb': locationBreadcrumb,
      'qty': quantity,
      'item_unit': unit,
      'item_condition': condition,
      'item_photo': imageUrl,
    };
  }
}
