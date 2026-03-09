<?php
$db = new PDO('mysql:host=localhost;dbname=attendance_db', 'root', '');
$tables = ['rpp', 'classes', 'grade_levels', 'subjects', 'education_units'];
$result = [];
foreach($tables as $t) {
  try {
    $stmt = $db->query("SHOW COLUMNS FROM $t");
    $result[$t] = $stmt->fetchAll(PDO::FETCH_COLUMN);
  } catch (Exception $e) {
    $result[$t] = 'Error or table missing';
  }
}
echo json_encode($result, JSON_PRETTY_PRINT);
