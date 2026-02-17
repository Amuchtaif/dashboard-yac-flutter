<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';
$db = (new PayrollDatabase())->getConnection();
$res = $db->query("SELECT id, tanggal, gaji_bulan FROM payrolls WHERE gaji_bulan LIKE '%2026%' OR tanggal LIKE '2026%' LIMIT 10")->fetchAll(PDO::FETCH_ASSOC);
print_r($res);
?>
