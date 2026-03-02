<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/db_mysqli.php';

$res = $mysqli->query("SHOW TABLES");
echo "Tables:\n";
while ($row = $res->fetch_array()) {
    $t = $row[0];
    if (stripos($t, 'dept') !== false || stripos($t, 'department') !== false) {
        echo "Found table: $t\n";
    }
}
?>
