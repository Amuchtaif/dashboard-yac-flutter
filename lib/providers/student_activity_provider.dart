import 'dart:io';
import 'package:flutter/material.dart';
import '../models/student_activity_model.dart';
import '../services/student_activity_service.dart';

class StudentActivityProvider with ChangeNotifier {
  final StudentActivityService _service = StudentActivityService();

  List<StudentActivity> _activities = [];
  List<ActivityType> _activityTypes = [];
  List<Map<String, dynamic>> _students = [];

  bool _isLoading = false;
  bool _isLoadingActivityTypes = false;
  bool _isLoadingStudents = false;
  bool _isLoadingMore = false;
  bool _isSaving = false;
  String? _errorMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  // Filters state
  int? _filterStudentId;
  int? _filterActivityTypeId;
  String? _filterStatus;
  String? _filterStartDate;
  String? _filterEndDate;
  String? _searchQuery;

  // Getters
  List<StudentActivity> get activities => _activities;
  List<ActivityType> get activityTypes => _activityTypes;
  List<Map<String, dynamic>> get students => _students;

  bool get isLoading => _isLoading || _isLoadingActivityTypes || _isLoadingStudents;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  bool get hasMore => _hasMore;

  // Filters Getters
  int? get filterStudentId => _filterStudentId;
  int? get filterActivityTypeId => _filterActivityTypeId;
  String? get filterStatus => _filterStatus;
  String? get filterStartDate => _filterStartDate;
  String? get filterEndDate => _filterEndDate;
  String? get searchQuery => _searchQuery;

  // Set filter variables and trigger fetch
  void setFilters({
    int? studentId,
    int? activityTypeId,
    String? status,
    String? startDate,
    String? endDate,
    String? search,
  }) {
    _filterStudentId = studentId;
    _filterActivityTypeId = activityTypeId;
    _filterStatus = status;
    _filterStartDate = startDate;
    _filterEndDate = endDate;
    _searchQuery = search;
    notifyListeners();
  }

  void clearFilters() {
    _filterStudentId = null;
    _filterActivityTypeId = null;
    _filterStatus = null;
    _filterStartDate = null;
    _filterEndDate = null;
    _searchQuery = null;
    notifyListeners();
  }

  // 1. Fetch Activity Types
  Future<void> fetchActivityTypes() async {
    if (_activityTypes.isNotEmpty) return; // cache locally
    _isLoadingActivityTypes = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _activityTypes = await _service.getActivityTypes();
    } catch (e) {
      _errorMessage = 'Gagal memuat jenis aktivitas: $e';
    } finally {
      _isLoadingActivityTypes = false;
      notifyListeners();
    }
  }

  // 2. Fetch Students
  Future<void> fetchStudents() async {
    _students = []; // Clear cached list to prevent displaying stale data across users/sessions
    _isLoadingStudents = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _students = await _service.getStudents();
    } catch (e) {
      _errorMessage = 'Gagal memuat daftar siswa: $e';
    } finally {
      _isLoadingStudents = false;
      notifyListeners();
    }
  }

  // 3. Fetch Activities (Infinite Scroll)
  Future<void> fetchActivities({bool refresh = false}) async {
    if (_isLoading || _isLoadingMore) return;

    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _activities = [];
      _isLoading = true;
    } else {
      if (!_hasMore) return;
      _isLoadingMore = true;
    }
    
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.getActivities(
        studentId: _filterStudentId,
        activityTypeId: _filterActivityTypeId,
        status: _filterStatus,
        startDate: _filterStartDate,
        endDate: _filterEndDate,
        search: _searchQuery,
        page: _currentPage,
        limit: 15,
      );

      if (result['success'] == true) {
        final List<StudentActivity> fetchedList = result['data'];
        if (refresh) {
          _activities = fetchedList;
        } else {
          _activities.addAll(fetchedList);
        }

        _totalPages = result['pages'] ?? 1;
        if (_currentPage >= _totalPages || fetchedList.isEmpty) {
          _hasMore = false;
        } else {
          _currentPage++;
        }
      } else {
        _errorMessage = 'Gagal mengambil data aktivitas.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // 4. Create Activity
  Future<bool> createActivity({
    required int activityTypeId,
    required int studentId,
    required String activityDate,
    required String status,
    String? startTime,
    String? endTime,
    String? note,
    List<File> attachments = const [],
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _service.createActivity(
        activityTypeId: activityTypeId,
        studentId: studentId,
        activityDate: activityDate,
        status: status,
        startTime: startTime,
        endTime: endTime,
        note: note,
      );

      if (res['success'] == true) {
        final newId = int.tryParse(res['id'].toString()) ?? 0;
        
        // Upload attachments if present
        if (newId > 0 && attachments.isNotEmpty) {
          for (var file in attachments) {
            await _service.uploadAttachment(newId, file);
          }
        }
        
        _isSaving = false;
        await fetchActivities(refresh: true);
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Gagal membuat aktivitas.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat menyimpan: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return false;
  }

  // 5. Create Batch Activities
  Future<bool> createBatchActivity({
    required int activityTypeId,
    required String activityDate,
    required String status,
    required List<int> studentIds,
    String? startTime,
    String? endTime,
    String? note,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _service.createBatchActivity(
        activityTypeId: activityTypeId,
        activityDate: activityDate,
        status: status,
        studentIds: studentIds,
        startTime: startTime,
        endTime: endTime,
        note: note,
      );

      if (res['success'] == true) {
        _isSaving = false;
        await fetchActivities(refresh: true);
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Gagal menyimpan checklist aktivitas.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat menyimpan checklist: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return false;
  }

  // 6. Update Activity
  Future<bool> updateActivity({
    required int id,
    int? activityTypeId,
    int? studentId,
    String? activityDate,
    String? status,
    String? startTime,
    String? endTime,
    String? note,
    List<File> attachmentsToAdd = const [],
    List<int> attachmentsToDelete = const [],
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Process API update info
      final res = await _service.updateActivity(
        id: id,
        activityTypeId: activityTypeId,
        studentId: studentId,
        activityDate: activityDate,
        status: status,
        startTime: startTime,
        endTime: endTime,
        note: note,
      );

      if (res['success'] == true) {
        // 2. Delete selected attachments
        for (var attId in attachmentsToDelete) {
          await _service.deleteAttachment(id, attId);
        }

        // 3. Upload new attachments
        for (var file in attachmentsToAdd) {
          await _service.uploadAttachment(id, file);
        }

        _isSaving = false;
        await fetchActivities(refresh: true);
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Gagal memperbarui aktivitas.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat memperbarui: $e';
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return false;
  }

  // 7. Delete Activity
  Future<bool> deleteActivity(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _service.deleteActivity(id);
      if (res['success'] == true) {
        _isLoading = false;
        await fetchActivities(refresh: true);
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Gagal menghapus aktivitas.';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat menghapus: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }
}
