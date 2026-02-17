<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';
$db = (new PayrollDatabase())->getConnection();
$res = $db->query("SELECT id, gaji_bulan FROM payrolls WHERE gaji_bulan LIKE '%September 2025%' LIMIT 1")->fetch(PDO::FETCH_ASSOC);
print_r($res);
?>
