<?php
// Seed a payroll record for testing
$_SERVER['REQUEST_METHOD'] = 'POST';
$input = [
    'user_id' => 10,
    'periode_bulan' => '02',
    'periode_tahun' => '2026',
    'gaji_pokok' => 5000000,
    'tunjangan_jabatan' => 1000000,
    'bonus_performa' => 500000,
    'lembur' => 200000,
    'pajak_pph21' => 100000,
    'bpjs_kesehatan' => 50000,
    'bpjs_ketenagakerjaan' => 75000,
    'potongan_kehadiran' => 0
];

// Mock php://input
function mock_post_data($data) {
    $tempFile = tempnam(sys_get_temp_dir(), 'php_input');
    file_put_contents($tempFile, json_encode($data));
    return $tempFile;
}

// Since I cannot easily mock php://input for the 'include' call directly in a way file_get_contents('php://input') works,
// I will manually call the service.

require_once 'd:/Xampp/htdocs/dashboard-yac/config/database.php';
require_once 'd:/Xampp/htdocs/dashboard-yac/config/PayrollDatabase.php';
require_once 'd:/Xampp/htdocs/dashboard-yac/app/Payroll/Repositories/PayrollRepository.php';
require_once 'd:/Xampp/htdocs/dashboard-yac/app/Payroll/Repositories/AttendanceRepository.php';
require_once 'd:/Xampp/htdocs/dashboard-yac/app/Payroll/Services/PayrollService.php';

use App\Payroll\Repositories\PayrollRepository;
use App\Payroll\Repositories\AttendanceRepository;
use App\Payroll\Services\PayrollService;

$attendanceDb = (new Database())->getConnection();
$payrollDb = (new PayrollDatabase())->getConnection();

$payrollRepo = new PayrollRepository($payrollDb);
$attendanceRepo = new AttendanceRepository($attendanceDb);
$payrollService = new PayrollService($payrollRepo, $attendanceRepo);

try {
    $result = $payrollService->processNewPayroll($input);
    echo "Seed result: " . json_encode($result) . "\n";
} catch (Exception $e) {
    echo "Seed failed: " . $e->getMessage() . "\n";
}
?>
