<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/database.php';

$db = (new Database())->getConnection();
$stmt = $db->query("SELECT id, nik, full_name, email FROM employees LIMIT 10");
$rows = $stmt->fetchAll();

echo "Employees sample:\n";
print_r($rows);
?>
