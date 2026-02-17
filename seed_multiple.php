<?php
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

$ids = [1, 10, 17];
foreach ($ids as $id) {
    $input = [
        'user_id' => $id,
        'periode_bulan' => '02',
        'periode_tahun' => '2026',
        'gaji_pokok' => 4000000 + (rand(1, 10) * 100000),
        'tunjangan_jabatan' => 500000,
        'bonus_performa' => 250000,
        'lembur' => 150000,
        'pajak_pph21' => 50000,
        'bpjs_kesehatan' => 45000,
        'bpjs_ketenagakerjaan' => 60000,
        'potongan_kehadiran' => 0
    ];
    try {
        $payrollService->processNewPayroll($input);
        echo "Created for ID $id\n";
    } catch (Exception $e) {
        echo "Failed for ID $id: " . $e->getMessage() . "\n";
    }
}
?>
