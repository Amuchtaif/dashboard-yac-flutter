import '../config/api_config.dart';

class ApiConstants {
  // Base URL for the API
  // NOTE: Use 'http://10.0.2.2/dashboard-yac/api/' for Android Emulator to access localhost
  // If testing on a real device, replace 10.0.2.2 with your machine's LAN IP address
  // e.g., 'http://192.168.1.10/dashboard-yac/api/'
  static const String baseUrl = '${ApiConfig.baseUrl}/';

  // Auth Endpoints
  static const String loginEndpoint = '${baseUrl}login.php';
  static const String changePassword = '${baseUrl}change_password.php';

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
  // Profile Endpoints
  static const String updateProfile = '${baseUrl}update_profile.php';

  // Class Endpoints
  static const String getClasses = '${baseUrl}get_classes.php';
  static const String getClassDetail = '${baseUrl}get_class_detail.php';
  static const String getSubjects = '${baseUrl}get_subjects.php';
  static String getCalendar = '${baseUrl}get_calendar.php';
  static const String getAttendanceRecap = '${baseUrl}get_attendance_recap.php';
  static const String getMeetingAttendees =
      '${baseUrl}get_meeting_attendees.php';

  // News Endpoints
  static const String getNews = '${baseUrl}get_news.php';
  static const String submitNews = '${baseUrl}submit_news.php';
  static const String toggleLikeNews = '${baseUrl}toggle_like.php';
  static const String viewNews = '${baseUrl}view_news.php';

  // Assignment Endpoints
  static const String getAssignments = '${baseUrl}assignment/get_list.php';
  static const String getAssignmentDetail =
      '${baseUrl}assignment/get_detail.php';
  static const String createAssignment = '${baseUrl}assignment/create.php';
  static const String updateAssignmentStatus =
      '${baseUrl}assignment/update_status.php';
  static const String updateAssignmentProgress =
      '${baseUrl}assignment/update_progress.php';
  static const String submitAssignmentReport =
      '${baseUrl}assignment/submit_report.php';
  static const String getSubordinates =
      '${baseUrl}assignment/get_subordinates.php';

  // Helper for Profile Photo
  static String getProfilePhotoUrl(String? filename) {
    if (filename == null || filename.isEmpty) return '';
    // ApiConfig.baseUrl is like "https://.../dashboard-yac/api"
    // We want "https://.../dashboard-yac/uploads/profile_photos/filename"
    final rootUrl = ApiConfig.baseUrl.replaceAll('/api', '');
    return "$rootUrl/uploads/profile_photos/$filename";
  }
}
