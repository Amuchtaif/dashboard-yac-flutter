<?php
$m = new mysqli('localhost', 'root', '', 'attendance_db');
$r = $m->query("SELECT * FROM positions WHERE name LIKE '%Pengawas%'");
while($row = $r->fetch_assoc()) print_r($row);

$r = $m->query("SELECT e.full_name, p.name as position FROM employees e JOIN positions p ON e.position_id = p.id WHERE e.full_name LIKE '%Pengawas%'");
while($row = $r->fetch_assoc()) print_r($row);
$m->close();
?>
