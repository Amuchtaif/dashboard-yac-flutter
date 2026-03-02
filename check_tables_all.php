<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/db_mysqli.php';

$res = $mysqli->query("SHOW TABLES");
echo "All Tables:\n";
while ($row = $res->fetch_array()) {
    echo $row[0] . "\n";
}
?>
