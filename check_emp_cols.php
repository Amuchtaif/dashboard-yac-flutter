<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/db_mysqli.php';

$res = $mysqli->query("SHOW COLUMNS FROM employees");
$cols = [];
while ($row = $res->fetch_array()) {
    $cols[] = $row[0];
}
echo "Columns in employees: " . implode(", ", $cols) . "\n";
echo "Total count: " . count($cols) . "\n";
?>
