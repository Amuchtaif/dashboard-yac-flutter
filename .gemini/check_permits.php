<?php
$m = new mysqli('localhost', 'root', '', 'attendance_db');
$r = $m->query('DESCRIBE permits');
while($row = $r->fetch_assoc()) echo $row['Field'] . " (" . $row['Type'] . ")\n";
$m->close();
?>
