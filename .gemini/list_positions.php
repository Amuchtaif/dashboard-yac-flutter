<?php
$m = new mysqli('localhost', 'root', '', 'attendance_db');
$res = $m->query("SELECT id, name, level FROM positions");
echo "--- ALL POSITIONS --- \n";
while($row = $res->fetch_assoc()) {
    echo $row['id'] . ": " . $row['name'] . " (Level " . $row['level'] . ")\n";
}
$m->close();
?>
