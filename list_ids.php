<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/database.php';
$db = (new Database())->getConnection();
$res = $db->query('SELECT id, full_name FROM employees LIMIT 20')->fetchAll();
foreach($res as $r) {
    echo $r['id'] . ': ' . $r['full_name'] . "\n";
}
?>
