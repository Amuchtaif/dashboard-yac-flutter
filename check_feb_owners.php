<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';
$db = (new PayrollDatabase())->getConnection();
$res = $db->query("SELECT nik, nama, gaji_bulan FROM payrolls WHERE gaji_bulan LIKE '%Februari 2026%' LIMIT 5")->fetchAll(PDO::FETCH_ASSOC);
print_r($res);
?>
