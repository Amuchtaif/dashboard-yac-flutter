# Permission API Documentation

## Overview
Dokumen ini menjelaskan API endpoint yang diperlukan untuk sistem permission-based UI pada fitur meeting.

## API Endpoint

### `GET /api/get_user_permissions.php`

Mengambil hak akses user berdasarkan user_id.

**Parameters:**
- `user_id` (required): ID user yang akan dicek permissionnya

**Response Success:**
```json
{
  "success": true,
  "message": "Permissions retrieved successfully",
  "data": {
    "can_create_meeting": 1,
    "can_approve_permit": 0,
    "can_view_all_meetings": 0
  }
}
```

**Response Error:**
```json
{
  "success": false,
  "message": "User not found"
}
```

## Database Schema

Tambahkan kolom permission ke tabel `users` atau buat tabel terpisah:

### Option 1: Tambah kolom di tabel users
```sql
ALTER TABLE users 
ADD COLUMN can_create_meeting TINYINT(1) DEFAULT 0;
```

### Option 2: Tabel permission terpisah (recommended untuk skalabilitas)
```sql
CREATE TABLE IF NOT EXISTS user_permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    permission_name VARCHAR(50) NOT NULL,
    permission_value TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_permission (user_id, permission_name)
);

-- Insert default permissions for existing users
INSERT INTO user_permissions (user_id, permission_name, permission_value)
SELECT id, 'can_create_meeting', 0 FROM users;
```

## PHP Implementation

Simpan file ini di folder `api/` di backend Anda.

### File: `api/get_user_permissions.php`

```php
<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");

require_once '../config/database.php';

// Get user_id from query parameter
$user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

if ($user_id <= 0) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid user_id parameter'
    ]);
    exit;
}

try {
    $conn = new PDO("mysql:host=$host;dbname=$dbname", $username, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Option 1: Jika menggunakan kolom di tabel users
    $stmt = $conn->prepare("
        SELECT can_create_meeting 
        FROM users 
        WHERE id = :user_id
    ");
    
    // Option 2: Jika menggunakan tabel permission terpisah
    // $stmt = $conn->prepare("
    //     SELECT 
    //         MAX(CASE WHEN permission_name = 'can_create_meeting' THEN permission_value ELSE 0 END) as can_create_meeting,
    //         MAX(CASE WHEN permission_name = 'can_approve_permit' THEN permission_value ELSE 0 END) as can_approve_permit,
    //         MAX(CASE WHEN permission_name = 'can_view_all_meetings' THEN permission_value ELSE 0 END) as can_view_all_meetings
    //     FROM user_permissions 
    //     WHERE user_id = :user_id
    // ");
    
    $stmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $stmt->execute();
    
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($result) {
        echo json_encode([
            'success' => true,
            'message' => 'Permissions retrieved successfully',
            'data' => [
                'can_create_meeting' => intval($result['can_create_meeting'] ?? 0)
            ]
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'message' => 'User not found'
        ]);
    }
    
} catch(PDOException $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $e->getMessage()
    ]);
}
?>
```

## Flutter Integration

Permission service sudah diintegrasikan pada:
1. **Login Flow** (`auth_service.dart`): Fetch permission setelah login berhasil
2. **Meeting List** (`meeting_list_screen.dart`): FAB hanya muncul jika `can_create_meeting == 1`
3. **Create Meeting** (`create_meeting_screen.dart`): Guard untuk mencegah akses paksa

## Testing

Untuk testing tanpa API, Anda bisa set permission secara manual:

```dart
// Di tempat yang appropriate (misal setelah login untuk testing)
final permissionService = PermissionService();
await permissionService.setPermission(canCreateMeeting: true);
```

## Admin Panel

Untuk mengelola permission user, tambahkan UI di admin panel untuk:
1. Set `can_create_meeting` = 1 untuk user yang diizinkan membuat rapat
2. Set `can_create_meeting` = 0 untuk user yang hanya bisa melihat undangan
