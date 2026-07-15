import 'package:flutter/material.dart';
import '../services/tahfidz_repository.dart';

class TahfidzDashboardProvider with ChangeNotifier {
  final TahfidzRepository _repository = TahfidzRepository();

  bool _isLoading = false;
  String? _errorMessage;

  // Filter States
  Map<String, dynamic> _filters = {
    'unit': '',
    'kelas': '',
    'halaqah_id': '',
    'pengampu_id': '',
    'date': '',
    'search': '',
  };

  // Dashboard Data Holders
  Map<String, dynamic> _summary = {};
  Map<String, dynamic> _attendance = {};
  Map<String, dynamic> _progress = {};
  Map<String, dynamic> _distribution = {};
  List<dynamic> _attentionList = [];
  List<dynamic> _comparison = [];
  List<dynamic> _rankings = [];
  Map<String, dynamic> _healthScore = {};
  List<dynamic> _activities = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic> get filters => _filters;

  Map<String, dynamic> get summary => _summary;
  Map<String, dynamic> get attendance => _attendance;
  Map<String, dynamic> get progress => _progress;
  Map<String, dynamic> get distribution => _distribution;
  List<dynamic> get attentionList => _attentionList;
  List<dynamic> get comparison => _comparison;
  List<dynamic> get rankings => _rankings;
  Map<String, dynamic> get healthScore => _healthScore;
  List<dynamic> get activities => _activities;

  TahfidzDashboardProvider() {
    _filters['date'] = DateTime.now().toIso8601String().split('T')[0];
  }

  void updateFilter(String key, dynamic value, int userId) {
    _filters[key] = value ?? '';
    // If unit changes, clear class filter
    if (key == 'unit') {
      _filters['kelas'] = '';
    }
    notifyListeners();
    fetchDashboardData(userId);
  }

  void clearFilters(int userId) {
    _filters = {
      'unit': '',
      'kelas': '',
      'halaqah_id': '',
      'pengampu_id': '',
      'date': DateTime.now().toIso8601String().split('T')[0],
      'search': '',
    };
    notifyListeners();
    fetchDashboardData(userId);
  }

  Future<void> fetchDashboardData(int userId) async {
    if (userId <= 0) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getPimpinanDashboard(userId, {'action': 'executive_summary', ..._filters}),
        _repository.getPimpinanDashboard(userId, {'action': 'attendance', ..._filters}),
        _repository.getPimpinanDashboard(userId, {'action': 'progress_hafalan', ..._filters}),
        _repository.getPimpinanDashboard(userId, {'action': 'distribusi_hafalan', ..._filters}),
        _repository.getPimpinanDashboard(userId, {'action': 'attention_needed', ..._filters}),
        _repository.getPimpinanDashboard(userId, {'action': 'compare_units', ..._filters}),
        _repository.getPimpinanDashboard(userId, {'action': 'ranking', ..._filters}),
        _repository.getPimpinanDashboard(userId, {'action': 'health_score', ..._filters}),
        _repository.getPimpinanDashboard(userId, {'action': 'live_activity', 'limit': '15', ..._filters}),
      ]).timeout(const Duration(seconds: 15));

      // Parse Executive Summary
      if (results[0]['success'] == true) {
        _summary = results[0]['data'] ?? {};
      }

      // Parse Attendance
      if (results[1]['success'] == true) {
        _attendance = results[1]['data'] ?? {};
      }

      // Parse Progress
      if (results[2]['success'] == true) {
        _progress = results[2]['data'] ?? {};
      }

      // Parse Distribution
      if (results[3]['success'] == true) {
        _distribution = results[3]['data'] ?? {};
      }

      // Parse Attention List
      if (results[4]['success'] == true) {
        _attentionList = results[4]['data'] ?? [];
      }

      // Parse Compare Units
      if (results[5]['success'] == true) {
        _comparison = results[5]['data'] ?? [];
      }

      // Parse Rankings
      if (results[6]['success'] == true) {
        _rankings = results[6]['data'] ?? [];
      }

      // Parse Health Score
      if (results[7]['success'] == true) {
        _healthScore = results[7]['data'] ?? {};
      }

      // Parse Activities
      if (results[8]['success'] == true) {
        _activities = results[8]['data'] ?? [];
      }

      _errorMessage = null;
    } catch (e) {
      debugPrint("Error fetching pimpinan dashboard: $e");
      _errorMessage = "Gagal memuat data dashboard. Mohon periksa jaringan Anda.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Drill down helper to navigate levels: Unit -> Class -> Halaqah
  Future<List<dynamic>> fetchDrillDown(int userId, String level, {String? parentId}) async {
    try {
      final res = await _repository.getPimpinanDashboard(userId, {
        'action': 'drill_down',
        'level': level,
        if (parentId != null) 'parent_id': parentId,
        ..._filters
      });
      if (res['success'] == true) {
        return res['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error in drill down fetch: $e");
    }
    return [];
  }

  // Fetch monitoring list (santri / halaqah)
  Future<List<dynamic>> fetchMonitoringList(int userId, String type) async {
    try {
      final action = type == 'santri' ? 'monitoring_santri' : 'monitoring_halaqoh';
      final res = await _repository.getPimpinanDashboard(userId, {
        'action': action,
        'limit': '150',
        ..._filters
      });
      if (res['success'] == true) {
        return res['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching monitoring list: $e");
    }
    return [];
  }
}
