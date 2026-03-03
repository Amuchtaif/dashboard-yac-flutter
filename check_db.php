<?php
require 'config/database.php';
$db = new Database();
$conn = $db->getConnection();
$stmt = $conn->query('DESCRIBE student_attendances');
while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    echo $row['Field'] . ' (' . $row['Type'] . ')' . PHP_EOL;
}
?>
