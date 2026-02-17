<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';

try {
    $db = (new PayrollDatabase())->getConnection();
    $stmt = $db->query("DESCRIBE payrolls");
    $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
    $out = "";
    foreach($rows as $row) {
        $out .= $row['Field'] . " - " . $row['Type'] . "\n";
    }
    file_put_contents('struct_output.txt', $out);
    echo "Done";
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
?>
