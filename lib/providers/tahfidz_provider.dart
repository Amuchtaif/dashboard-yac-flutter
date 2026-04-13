import 'package:flutter/material.dart';
import '../services/tahfidz_service.dart';

class TahfidzProvider with ChangeNotifier {
  final TahfidzService _service = TahfidzService();

  List<dynamic> _myStudents = [];
  bool _isLoading = false;
  String? _teacherName;
  int? _teacherId;

  // Status flags
  bool _isHalaqohOpened = false;
  bool _isAttendanceSubmitted = false;
  String? _activeSession;

  List<dynamic> get myStudents => _myStudents;
  bool get isLoading => _isLoading;
  String? get teacherName => _teacherName;
  int? get teacherId => _teacherId;
  bool get isHalaqohOpened => _isHalaqohOpened;
  bool get isAttendanceSubmitted => _isAttendanceSubmitted;
  String? get activeSession => _activeSession;

  Future<void> fetchMyStudents(int? teacherId, {String? teacherName}) async {
    _teacherId = teacherId;
    _teacherName = teacherName;
    _isLoading = true;
    notifyListeners();

    try {
      _myStudents = await _service.getMyStudents(teacherId);
      await checkHalaqohStatus();
    } catch (e) {
      debugPrint("Error in TahfidzProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> checkHalaqohStatus() async {
    if (_teacherId == null) return;

    try {
      final String today = DateTime.now().toIso8601String().split('T')[0];
      
      // 1. Check if Halaqoh is opened (Teacher Check-in)
      final history = await _service.getTeacherAttendanceHistory(
        teacherId: _teacherId,
        date: today,
      );

      final activeSession = history.firstWhere(
        (h) => h['check_out_time'] == null || h['check_out_time'] == "",
        orElse: () => null,
      );

      if (activeSession != null) {
        _isHalaqohOpened = true;
        _activeSession = activeSession['notes'] ?? 'Pagi';
        
        // 2. Check if Student Attendance submitted for this session
        final attendanceHistory = await _service.getStudentAttendanceHistory(
          date: today,
          session: _activeSession,
        );
        _isAttendanceSubmitted = attendanceHistory.isNotEmpty;
      } else {
        _isHalaqohOpened = false;
        _isAttendanceSubmitted = false;
        _activeSession = null;
      }
    } catch (e) {
      debugPrint("Error checking halaqoh status in provider: $e");
    }
    notifyListeners();
  }

  void setTeacherInfo(int? id, String? name) {
    _teacherId = id;
    _teacherName = name;
    notifyListeners();
  }
}
