<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/db_mysqli.php';

echo "Full unit_id distribution:\n";
$res = $mysqli->query("SELECT unit_id, COUNT(*) as count FROM employees GROUP BY unit_id");
while ($row = $res->fetch_assoc()) {
    echo json_encode($row) . "\n";
}
?>
