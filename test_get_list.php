<?php
include 'd:\xampp\htdocs\dashboard-yac\api\config\database.php';
$db = (new Database())->getConnection();
$where = "r.employee_id = 199 AND r.is_draft = 1";
$query = "
    SELECT 
        r.id, 
        r.title, 
        r.semester, 
        r.created_at, 
        r.is_draft, 
        s.name as subject_name, 
        gl.name as grade_name, 
        ay.name as academic_year_name
    FROM rpp r
    LEFT JOIN subjects s ON r.subject_id = s.id
    LEFT JOIN grade_levels gl ON r.grade_level_id = gl.id
    LEFT JOIN academic_years ay ON r.academic_year_id = ay.id
    WHERE $where
    ORDER BY r.created_at DESC
";
$stmt = $db->query($query);
echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
