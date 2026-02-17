<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';
$db = (new PayrollDatabase())->getConnection();
$nik = '0101.70.014';
$stmt = $db->query("SELECT id, nik, gaji_bulan, tanggal FROM payrolls WHERE nik = '$nik' ORDER BY id DESC LIMIT 5");
$rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
foreach($rows as $row) {
    echo "ID:{$row['id']} | NIK:{$row['nik']} | Month:{$row['gaji_bulan']} | Date:{$row['tanggal']}\n";
}
?>
