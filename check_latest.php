<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';

try {
    $db = (new PayrollDatabase())->getConnection();
    // Check all records, ordered by ID desc to see what was last added, and also by tanggal desc
    $stmt = $db->query("SELECT id, id_payroll, tanggal, gaji_bulan, nik, nama FROM payrolls ORDER BY id DESC LIMIT 5");
    $latestById = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $stmt = $db->query("SELECT id, id_payroll, tanggal, gaji_bulan, nik, nama FROM payrolls ORDER BY tanggal DESC LIMIT 5");
    $latestByTanggal = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'latest_by_id' => $latestById,
        'latest_by_tanggal' => $latestByTanggal
    ], JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
