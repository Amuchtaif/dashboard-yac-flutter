<?php
$m = new mysqli('localhost', 'root', '', 'attendance_db');
$r = $m->query("SELECT * FROM positions WHERE level <= 3");
while($row = $r->fetch_assoc()) echo $row['name'] . " (Level " . $row['level'] . ")\n";
$m->close();
?>
