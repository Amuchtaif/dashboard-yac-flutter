<?php
$m = new mysqli('localhost', 'root', '', 'attendance_db');
$res = $m->query("SELECT id, name, level FROM positions WHERE name LIKE '%Kepala Unit%' OR name LIKE '%Kasubid%' OR name LIKE '%Pengawas%' OR name LIKE '%Staff%'");
echo "--- Positions --- \n";
while($row = $res->fetch_assoc()) {
    echo $row['id'] . ": " . $row['name'] . " (Level " . $row['level'] . ")\n";
}

echo "\n--- Pendidikan Members (ID 2) with their positions ---\n";
$res = $m->query("SELECT e.full_name, p.name as position, e.department_id, e.division_id 
               FROM employees e 
               LEFT JOIN positions p ON e.position_id = p.id
               WHERE (e.department_id = 2 OR e.division_id = 2)
               AND e.status = 'active'");
while($row = $res->fetch_assoc()) {
    echo $row['full_name'] . " | " . $row['position'] . " | Dept: " . $row['department_id'] . " | Div: " . $row['division_id'] . "\n";
}
$m->close();
?>
