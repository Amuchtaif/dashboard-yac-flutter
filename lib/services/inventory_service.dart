import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/inventory_item_model.dart';
import '../models/inventory_location_model.dart';
import '../core/api_constants.dart';

class InventoryService {
  Future<List<InventoryItemModel>> getItems({String search = '', int? locationId}) async {
    try {
      final url = Uri.parse('${ApiConstants.inventoryGetItems}?search=$search${locationId != null ? '&location_id=$locationId' : ''}');
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list
              .whereType<Map<String, dynamic>>()
              .map((json) => InventoryItemModel.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetch items: $e');
    }
    return [];
  }

  Future<List<InventoryLocationModel>> getLocations() async {
    try {
      final url = Uri.parse(ApiConstants.inventoryGetLocations);
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> list = data['data'];
          return list
              .whereType<Map<String, dynamic>>()
              .map((json) => InventoryLocationModel.fromJson(json))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetch locations: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> saveItem(Map<String, dynamic> itemData) async {
    try {
      final bool isUpdate = itemData['id'] != null && itemData['id'] != 0;
      final url = Uri.parse(ApiConstants.inventorySaveItem);
      
      final response = await (isUpdate 
        ? http.put(url, 
            headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'}, 
            body: jsonEncode(itemData))
        : http.post(url, 
            headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'}, 
            body: jsonEncode(itemData)));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Save item with optional image file using Multipart
  Future<Map<String, dynamic>> saveItemMultipart({
    required Map<String, dynamic> itemData,
    File? imageFile,
  }) async {
    try {
      final url = Uri.parse(ApiConstants.inventorySaveItem);
      
      // Use POST for both create and update since many PHP environments handle multipart PUT poorly
      final request = http.MultipartRequest('POST', url);
      
      // Headers
      request.headers.addAll({
        'ngrok-skip-browser-warning': 'true',
      });

      // Fields
      itemData.forEach((key, value) {
        request.fields[key] = value.toString();
      });

      // File
      if (imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'item_photo',
          imageFile.path,
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      // Safety check for HTML responses
      if (responseBody.trim().toLowerCase().startsWith('<!doctype html') || 
          responseBody.trim().toLowerCase().startsWith('<html')) {
        return {
          'success': false, 
          'message': 'Server mengembalikan halaman HTML (Status ${response.statusCode}). '
                     'Kemungkinan terjadi kesalahan server atau URL tidak ditemukan.'
        };
      }

      try {
        return jsonDecode(responseBody);
      } catch (e) {
        return {
          'success': false, 
          'message': 'Gagal mengurai respon server: $responseBody'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteItem(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.inventoryDeleteItem),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'id': id}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  Future<Map<String, dynamic>> saveLocation(Map<String, dynamic> locationData) async {
    try {
      final bool isUpdate = locationData['id'] != null && locationData['id'] != 0;
      final url = Uri.parse(ApiConstants.inventorySaveLocation);
      
      final response = await (isUpdate 
        ? http.put(url, 
            headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'}, 
            body: jsonEncode(locationData))
        : http.post(url, 
            headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'}, 
            body: jsonEncode(locationData)));

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteLocation(int id) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.inventoryDeleteLocation),
        headers: {'Content-Type': 'application/json', 'ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({'id': id}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}

