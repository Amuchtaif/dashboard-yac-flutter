<?php
$m = new mysqli('localhost', 'root', '', 'attendance_db');
$r = $m->query("SELECT e.full_name, p.name as position 
               FROM employees e 
               JOIN positions p ON e.position_id = p.id 
               WHERE (e.department_id = 2 OR e.division_id = 2) 
               AND (p.name LIKE '%Koordinator%' OR p.name LIKE '%Pengawas%' OR p.name LIKE '%Kepala Unit%' OR p.name LIKE '%Kepala Sub%')");
while($row = $r->fetch_assoc()) echo $row['full_name'] . " | " . $row['position'] . "\n";
$m->close();
?>
