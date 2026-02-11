import '../services/permission_service.dart';

class AccessControl {
  /// Helper untuk mengecek apakah user memiliki permission tertentu.
  /// Contoh: AccessControl.can('can_access_tahfidz')
  static bool can(String permissionName) {
    return PermissionService().hasPermission(permissionName);
  }

  /// Helper untuk mengecek salah satu dari list permission
  static bool canAny(List<String> permissions) {
    for (var p in permissions) {
      if (can(p)) return true;
    }
    return false;
  }
}
