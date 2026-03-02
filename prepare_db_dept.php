<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/db_mysqli.php';

// 1. Alter employees table to add department_id if missing
$res = $mysqli->query("SHOW COLUMNS FROM employees LIKE 'department_id'");
if ($res->num_rows === 0) {
    if ($mysqli->query("ALTER TABLE employees ADD COLUMN department_id INT NULL AFTER division_id")) {
        echo "Column department_id added to employees.\n";
        // Optional: populate it with division_id if it's there
        if ($mysqli->query("UPDATE employees SET department_id = division_id")) {
             echo "department_id populated with division_id.\n";
        }
    } else {
        echo "Error adding column: " . $mysqli->error . "\n";
    }
} else {
    echo "Column department_id already exists.\n";
}

// 2. Add sample departments if empty
$res = $mysqli->query("SELECT COUNT(*) as count FROM departments");
$row = $res->fetch_assoc();
if ($row['count'] == 0) {
    echo "Departments table is empty. Copying from divisions...\n";
    if ($mysqli->query("INSERT INTO departments (id, name) SELECT id, name FROM divisions")) {
        echo "Departments populated from divisions.\n";
    } else {
        echo "Error populating departments: " . $mysqli->error . "\n";
    }
}

// 3. Ensure some employees have department_id (for testing "ada karyawan di bidang tersebut")
if ($mysqli->query("UPDATE employees SET department_id = 7 WHERE division_id = 7")) {
    echo "Assigned some employees to department 7.\n";
}

echo "Database preparation done.\n";
?>
