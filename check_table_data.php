<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/db_mysqli.php';

$tables = ['departments', 'divisions'];
$result_output = "";

foreach ($tables as $table) {
    $result_output .= "--- Data in: $table ---\n";
    $res = $mysqli->query("SELECT * FROM $table");
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $result_output .= json_encode($row) . "\n";
        }
    } else {
        $result_output .= "Table NOT found or query failed.\n";
    }
    $result_output .= "\n";
}

file_put_contents('c:/src/Project/dashboard-yac/table_data.txt', $result_output);
echo "Done";
?>
