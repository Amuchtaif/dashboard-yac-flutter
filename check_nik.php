<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/database.php';
$db = (new Database())->getConnection();
$stmt = $db->query("SELECT id, nik, full_name FROM employees WHERE nik = '0101.70.014'");
print_r($stmt->fetch());
?>
