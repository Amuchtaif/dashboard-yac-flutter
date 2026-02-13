<?php
/**
 * get_user_permissions.php
 * 
 * API untuk mengambil daftar permission/hak akses user.
 * Menggunakan sistem hybrid:
 *   1. Cek tabel user_permissions untuk override per-user
 *   2. Fallback ke permission default berdasarkan posisi/jabatan (tabel positions)
 * 
 * Request: GET ?user_id=123
 * Response: { success: true, data: { user_id: 123, permissions: { ... } } }
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, ngrok-skip-browser-warning');

// Jika preflight request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Include database config
require_once __DIR__ . '/../config/database.php';

// Validasi parameter
if (!isset($_GET['user_id']) || empty($_GET['user_id'])) {
    echo json_encode([
        'success' => false,
        'message' => 'Parameter user_id diperlukan'
    ]);
    exit;
}

$user_id = intval($_GET['user_id']);

try {
    // Daftar semua permission yang tersedia di sistem
    // KEY HARUS SAMA persis dengan nama kolom di tabel positions
    $all_permissions = [
        'can_create_meeting',
        'can_approve_permits',
        'can_access_tahfidz',
        'is_koordinator',
    ];

    // Inisialisasi semua permission dengan default false
    $permissions = [];
    foreach ($all_permissions as $perm) {
        $permissions[$perm] = 0;
    }

    // ====================================
    // STEP 1: Cek override di user_permissions
    // ====================================
    $stmt = $conn->prepare("SELECT permission_name, is_granted FROM user_permissions WHERE user_id = ?");
    
    if ($stmt) {
        $stmt->bind_param("i", $user_id);
        $stmt->execute();
        $result = $stmt->get_result();

        $has_overrides = false;
        while ($row = $result->fetch_assoc()) {
            $has_overrides = true;
            $perm_name = $row['permission_name'];
            if (in_array($perm_name, $all_permissions)) {
                $permissions[$perm_name] = intval($row['is_granted']);
            }
        }
        $stmt->close();

        // Jika user punya override, langsung return
        if ($has_overrides) {
            echo json_encode([
                'success' => true,
                'data' => [
                    'user_id' => $user_id,
                    'source' => 'user_override',
                    'permissions' => $permissions
                ]
            ]);
            exit;
        }
    }

    // ====================================
    // STEP 2: Fallback ke permission default dari posisi
    // ====================================
    $stmt2 = $conn->prepare("
        SELECT p.can_create_meeting, p.can_approve_permits, p.can_access_tahfidz, p.is_koordinator
        FROM employees e 
        JOIN positions p ON e.position_id = p.id 
        WHERE e.user_id = ?
    ");

    if ($stmt2) {
        $stmt2->bind_param("i", $user_id);
        $stmt2->execute();
        $result2 = $stmt2->get_result();

        if ($row2 = $result2->fetch_assoc()) {
            $permissions['can_create_meeting'] = intval($row2['can_create_meeting'] ?? 0);
            $permissions['can_approve_permits'] = intval($row2['can_approve_permits'] ?? 0);
            $permissions['can_access_tahfidz'] = intval($row2['can_access_tahfidz'] ?? 0);
            $permissions['is_koordinator'] = intval($row2['is_koordinator'] ?? 0);
        }
        $stmt2->close();
    }

    echo json_encode([
        'success' => true,
        'data' => [
            'user_id' => $user_id,
            'source' => 'position_default',
            'permissions' => $permissions
        ]
    ]);

} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
