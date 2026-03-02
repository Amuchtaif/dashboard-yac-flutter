<?php
require_once 'd:/Xampp/htdocs/dashboard-yac/config/db_mysqli.php';

// 1. Add department_id to meetings table if missing
$res = $mysqli->query("SHOW COLUMNS FROM meetings LIKE 'department_id'");
if ($res->num_rows === 0) {
    if ($mysqli->query("ALTER TABLE meetings ADD COLUMN department_id INT NULL AFTER division_id")) {
        echo "Column department_id added to meetings.\n";
        // Migrate existing division_id to department_id
        if ($mysqli->query("UPDATE meetings SET department_id = division_id")) {
             echo "department_id populated with division_id in meetings table.\n";
        }
    } else {
        echo "Error adding column to meetings: " . $mysqli->error . "\n";
    }
} else {
    echo "Column department_id already exists in meetings table.\n";
}

echo "Database migration for meetings table done.\n";
?>
