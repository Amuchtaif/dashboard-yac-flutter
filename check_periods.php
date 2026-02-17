<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';

try {
    $db = (new PayrollDatabase())->getConnection();
    $stmt = $db->query("SELECT periode_bulan, periode_tahun, count(*) as total FROM payrolls GROUP BY periode_tahun, periode_bulan ORDER BY periode_tahun DESC, periode_bulan DESC");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($rows, JSON_PRETTY_PRINT);
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
