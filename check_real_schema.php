<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/db_mysqli.php';

$tables = ['employees', 'departments', 'divisions', 'units', 'positions'];
$result_output = "";

foreach ($tables as $table) {
    $result_output .= "--- Table: $table ---\n";
    $res = $mysqli->query("DESCRIBE $table");
    if ($res) {
        while ($row = $res->fetch_assoc()) {
            $result_output .= $row['Field'] . " (" . $row['Type'] . ")\n";
        }
    } else {
        $result_output .= "Table NOT found.\n";
    }
    $result_output .= "\n";
}

file_put_contents('c:/src/Project/dashboard-yac/real_schema.txt', $result_output);
echo "Done";
?>
