<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';

$db = (new PayrollDatabase())->getConnection();
$stmt = $db->query("SELECT COUNT(*) as count FROM payrolls");
$row = $stmt->fetch();

echo "Total payroll records: " . $row['count'] . "\n";

if ($row['count'] > 0) {
    $stmt = $db->query("SELECT * FROM payrolls LIMIT 5");
    $rows = $stmt->fetchAll();
    print_r($rows);
} else {
    echo "The payrolls table is empty.\n";
}
?>
