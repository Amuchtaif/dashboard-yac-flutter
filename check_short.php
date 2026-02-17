<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';
$db = (new PayrollDatabase())->getConnection();
$res = $db->query("SELECT id, id_payroll, tanggal, gaji_bulan FROM payrolls ORDER BY tanggal DESC LIMIT 20")->fetchAll(PDO::FETCH_ASSOC);
foreach($res as $r) {
    echo "ID: {$r['id']} | Date: {$r['tanggal']} | IDP: {$r['id_payroll']} | Month: {$r['gaji_bulan']}\n";
}
?>
