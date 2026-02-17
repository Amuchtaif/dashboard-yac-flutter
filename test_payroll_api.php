<?php
$_SERVER['REQUEST_METHOD'] = 'GET';
$_GET['user_id'] = 186;
$_GET['bulan'] = '09';
$_GET['tahun'] = '2025';

try {
    include 'd:/Xampp/htdocs/dashboard-yac/api/payroll.php';
} catch (Exception $e) {
    echo "Caught: " . $e->getMessage();
}
?>
