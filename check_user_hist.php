<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';
$db = (new PayrollDatabase())->getConnection();
$nik = '0101.70.014';
$res = $db->query("SELECT id, tanggal, gaji_bulan FROM payrolls WHERE nik = '$nik' ORDER BY id DESC LIMIT 20")->fetchAll(PDO::FETCH_ASSOC);
foreach($res as $r) {
    echo "ID: {$r['id']} | Date: {$r['tanggal']} | Month: {$r['gaji_bulan']}\n";
}
?>
