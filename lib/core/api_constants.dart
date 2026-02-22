import '../config/api_config.dart';

class ApiConstants {
  // Base URL for the API
  // NOTE: Use 'http://10.0.2.2/dashboard-yac/api/' for Android Emulator to access localhost
  // If testing on a real device, replace 10.0.2.2 with your machine's LAN IP address
  // e.g., 'http://192.168.1.10/dashboard-yac/api/'
  static const String baseUrl = '${ApiConfig.baseUrl}/';

  // Auth Endpoints
  static const String loginEndpoint = '${baseUrl}login.php';

  // Teacher Endpoints
  static const String teacherSchedule = '${baseUrl}teacher/get_schedule.php';
  static const String teacherStudents =
      '${baseUrl}teacher/get_students_by_schedule.php';
  static const String submitTeacherAttendance =
      '${baseUrl}teacher/submit_attendance.php';

  // Performance Endpoints
  static const String performanceData = '${baseUrl}get_performance_data.php';
  static const String performanceLeaderboard =
      '${baseUrl}get_performance_leaderboard.php';
}
