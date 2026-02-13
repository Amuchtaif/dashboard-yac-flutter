import 'package:flutter/material.dart';
import '../services/tahfidz_service.dart';

class TahfidzProvider with ChangeNotifier {
  final TahfidzService _service = TahfidzService();

  List<dynamic> _myStudents = [];
  bool _isLoading = false;
  String? _teacherName;
  int? _teacherId;

  List<dynamic> get myStudents => _myStudents;
  bool get isLoading => _isLoading;
  String? get teacherName => _teacherName;
  int? get teacherId => _teacherId;

  Future<void> fetchMyStudents(int? teacherId, {String? teacherName}) async {
    _teacherId = teacherId;
    _teacherName = teacherName;
    _isLoading = true;
    notifyListeners();

    try {
      _myStudents = await _service.getMyStudents(teacherId);
    } catch (e) {
      debugPrint("Error in TahfidzProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTeacherInfo(int? id, String? name) {
    _teacherId = id;
    _teacherName = name;
    notifyListeners();
  }
}
