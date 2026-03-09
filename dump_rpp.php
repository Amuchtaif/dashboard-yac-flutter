<?php
$db = new PDO('mysql:host=localhost;dbname=attendance_db', 'root', '');
$stmt = $db->query('select * from rpp order by id desc limit 2');
echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
