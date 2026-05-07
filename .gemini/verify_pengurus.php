<?php
$m = new mysqli('localhost', 'root', '', 'attendance_db');

function test_dept($m, $id, $name) {
    echo "--- Testing Dept: $name (ID $id) ---\n";
    if ($id == 1) {
        $sql = "SELECT e.full_name, p.name as position 
                FROM employees e
                INNER JOIN positions p ON e.position_id = p.id
                WHERE p.level IN (1, 2) 
                AND e.full_name NOT LIKE '%Administrator%'
                AND e.status = 'active' 
                ORDER BY e.full_name ASC";
        $stmt = $m->prepare($sql);
    } else {
        $sql = "SELECT id, full_name FROM employees 
                WHERE (department_id = ? OR division_id = ?) 
                AND status = 'active' 
                ORDER BY full_name ASC";
        $stmt = $m->prepare($sql);
        $stmt->bind_param("ii", $id, $id);
    }
    $stmt->execute();
    $res = $stmt->get_result();
    while($row = $res->fetch_assoc()) {
        echo "- " . $row['full_name'] . (isset($row['position']) ? " (".$row['position'].")" : "") . "\n";
    }
    echo "\n";
}

test_dept($m, 1, "Pengurus");
test_dept($m, 5, "Bendahara");

$m->close();
?>
