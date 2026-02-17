<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';

try {
    $db = (new PayrollDatabase())->getConnection();
    $stmt = $db->query("SELECT id_payroll, tanggal, gaji_bulan, nik, nama, gapok, gaji_netto FROM payrolls LIMIT 10");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    file_put_contents('sample_data.json', json_encode($rows, JSON_PRETTY_PRINT));
    echo "Done";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
