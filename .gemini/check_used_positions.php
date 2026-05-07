<?php
$m = new mysqli('localhost', 'root', '', 'attendance_db');
$r = $m->query("SELECT DISTINCT position_id FROM employees");
while($row = $r->fetch_assoc()) {
    $pid = $row['position_id'];
    $r2 = $m->query("SELECT name FROM positions WHERE id = $pid");
    $pname = $r2->fetch_assoc()['name'] ?? 'UNKNOWN';
    echo "$pid: $pname\n";
}
$m->close();
?>
