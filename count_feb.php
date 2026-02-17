<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';
$db = (new PayrollDatabase())->getConnection();
$res = $db->query("SELECT count(*) as total FROM payrolls WHERE gaji_bulan LIKE '%Februari 2026%'")->fetch(PDO::FETCH_ASSOC);
echo "Total Feb 2026: " . $res['total'] . "\n";

$res = $db->query("SELECT id, nik, nama, gaji_bulan, tanggal FROM payrolls WHERE gaji_bulan LIKE '%Februari 2026%' LIMIT 5")->fetchAll(PDO::FETCH_ASSOC);
print_r($res);
?>
