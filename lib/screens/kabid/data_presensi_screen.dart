import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_constants.dart';
import '../../models/staff_attendance_model.dart';
import '../../services/kabid_service.dart';

class DataPresensiScreen extends StatefulWidget {
  const DataPresensiScreen({super.key});

  @override
  State<DataPresensiScreen> createState() => _DataPresensiScreenState();
}

class _DataPresensiScreenState extends State<DataPresensiScreen> {
  final KabidService _kabidService = KabidService();
  List<StaffAttendance> _attendanceList = [];
  List<String> _availableUnits = ['Semua Unit'];
  String _selectedUnit = 'Semua Unit';
  String _departmentName = 'Semua Unit';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isExcludedUnit(String unitName) {
    final normalized = unitName.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (normalized.contains('pengawas')) return true;
    if (normalized.contains('sub kurikulum') ||
        normalized.contains('sub-kurikulum') ||
        (normalized.contains('sub') && normalized.contains('kurikulum'))) {
      return true;
    }
    return false;
  }

  Future<void> _fetchAttendance() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;
      final positionLevel = prefs.getInt('positionLevel') ?? 99;
      final positionName =
          (prefs.getString('positionName') ?? '').trim().toLowerCase();
      final divisionName = (prefs.getString('divisionName') ?? '').trim();
      final unitName = (prefs.getString('unitName') ?? '').trim();

      // Detect if user is a Kepala Unit (Kanit)
      final bool isKepalaUnit =
          positionLevel == 3 ||
          positionName.contains('kepala unit') ||
          positionName.contains('kanit');

      String departmentName = 'Semua Unit';
      if (isKepalaUnit && unitName.isNotEmpty) {
        departmentName = unitName;
      } else if (divisionName.isNotEmpty) {
        departmentName = divisionName;
      } else if (unitName.isNotEmpty) {
        departmentName = unitName;
      }

      if (_selectedUnit == 'Semua Unit' || _selectedUnit == _departmentName) {
        _selectedUnit = departmentName;
      }
      _departmentName = departmentName;

      final String? queryUnit =
          (_selectedUnit == _departmentName || _selectedUnit == 'Semua Unit')
              ? null
              : _selectedUnit;

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final results = await Future.wait([
        _kabidService.getStaffListData(userId, unit: queryUnit),
        _kabidService.getStaffAttendance(
          userId: userId,
          date: dateStr,
          unit: queryUnit,
        ),
      ]);

      final Map<String, dynamic> staffData = results[0] as Map<String, dynamic>;
      final List<Map<String, dynamic>> staffList =
          staffData['staff'] as List<Map<String, dynamic>>;
      final List<Map<String, dynamic>> backendUnits =
          staffData['units'] as List<Map<String, dynamic>>;
      final List<StaffAttendance> attendanceList =
          results[1] as List<StaffAttendance>;

      // Merge: Map all staff under Kabid/Kanit to their attendance status
      List<StaffAttendance> mergedList =
          staffList.map((s) {
            final sId =
                s['id'] is int
                    ? s['id']
                    : int.tryParse(s['id']?.toString() ?? '0') ?? 0;
            final staffUnit =
                (s['unit_name'] ??
                        s['unit'] ??
                        s['division_name'] ??
                        s['division'] ??
                        '')
                    .toString()
                    .trim();
            final found = attendanceList.firstWhere(
              (a) => a.id == sId,
              orElse:
                  () => StaffAttendance(
                    id: sId,
                    name: s['name'] ?? '',
                    position: s['position_name'] ?? s['position'] ?? '',
                    photo: s['profile_photo'] ?? s['photo'],
                    time: '-',
                    status: 'Alpha',
                    unit: staffUnit,
                  ),
            );

            return StaffAttendance(
              id: found.id,
              name: found.name.isNotEmpty ? found.name : (s['name'] ?? ''),
              position:
                  found.position.isNotEmpty
                      ? found.position
                      : (s['position_name'] ?? s['position'] ?? ''),
              photo: found.photo ?? s['profile_photo'] ?? s['photo'],
              time: found.time,
              status: found.status,
              unit: found.unit.isNotEmpty ? found.unit : staffUnit,
            );
          }).toList();

      // Check if there is sub-structure (child units) below this Kepala Unit
      bool hasSubStructure = false;
      for (var u in backendUnits) {
        final name = (u['unit_name'] ?? u['name'] ?? '').toString().trim();
        if (name.isNotEmpty &&
            !_isExcludedUnit(name) &&
            name.toLowerCase() != departmentName.toLowerCase()) {
          hasSubStructure = true;
          break;
        }
      }

      // Build available units list
      // If user is a Kepala Unit without child structure, only display their unit
      final Set<String> unitSet = {departmentName};
      if (!isKepalaUnit || hasSubStructure) {
        for (var u in backendUnits) {
          final name = (u['unit_name'] ?? u['name'] ?? '').toString().trim();
          if (name.isNotEmpty && !_isExcludedUnit(name)) unitSet.add(name);
        }
        for (var item in mergedList) {
          if (item.unit.isNotEmpty && !_isExcludedUnit(item.unit)) {
            unitSet.add(item.unit);
          }
        }
      }
      final availableUnits = unitSet.toList();

      setState(() {
        _attendanceList = mergedList;
        _availableUnits = availableUnits;
        if (!_availableUnits.contains(_selectedUnit)) {
          _selectedUnit = departmentName;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat data: $e')));
      }
    }
  }

  List<StaffAttendance> get _filteredAttendanceList {
    return _attendanceList.where((item) {
      final matchesUnit =
          _selectedUnit == _departmentName ||
          _selectedUnit == 'Semua Unit' ||
          item.unit.trim().toLowerCase() == _selectedUnit.trim().toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.position.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.unit.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesUnit && matchesSearch;
    }).toList();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildFilterSection(),
            if (!_isLoading && _attendanceList.isNotEmpty) _buildSummaryCards(),
            Expanded(
              child: _isLoading ? _buildLoadingState() : _buildAttendanceList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 1,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Data Presensi Pegawai',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Row 1: Date Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TANGGAL',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('Ganti'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEFF6FF),
                  foregroundColor: const Color(0xFF2563EB),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Unit Filter & Search
          Row(
            children: [
              // Unit Dropdown
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedUnit,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                      items:
                          _availableUnits.map((String unit) {
                            return DropdownMenuItem<String>(
                              value: unit,
                              child: Text(
                                unit,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null && newValue != _selectedUnit) {
                          setState(() {
                            _selectedUnit = newValue;
                          });
                          _fetchAttendance();
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Search Field
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF1E293B),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Cari nama...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      icon: const Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon:
                          _searchQuery.isNotEmpty
                              ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final list = _filteredAttendanceList;
    int hadir = list.where((e) => e.status == 'Hadir').length;
    int terlambat = list.where((e) => e.status == 'Terlambat').length;
    int izin =
        list.where((e) => ['Izin', 'Sakit', 'Cuti'].contains(e.status)).length;
    int alpha =
        list
            .where(
              (e) =>
                  ![
                    'Hadir',
                    'Terlambat',
                    'Izin',
                    'Sakit',
                    'Cuti',
                  ].contains(e.status),
            )
            .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _buildStatItem('HADIR', hadir, const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildStatItem('TELAT', terlambat, const Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          _buildStatItem('IZIN', izin, const Color(0xFF3B82F6)),
          const SizedBox(width: 8),
          _buildStatItem('ALPHA', alpha, const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.9),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildAttendanceList() {
    final list = _filteredAttendanceList;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _attendanceList.isEmpty
                  ? 'Tidak ada data presensi'
                  : 'Tidak ada staf yang sesuai filter',
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        Color statusColor;
        switch (item.status) {
          case 'Hadir':
            statusColor = const Color(0xFF10B981);
            break;
          case 'Terlambat':
            statusColor = const Color(0xFFF59E0B);
            break;
          case 'Izin':
          case 'Sakit':
          case 'Cuti':
            statusColor = const Color(0xFF3B82F6);
            break;
          default:
            statusColor = const Color(0xFFEF4444); // Alpha/Unknown
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF1F5F9),
                ),
                child: ClipOval(
                  child: () {
                    final photoUrl = ApiConstants.getProfilePhotoUrl(
                      item.photo,
                    );
                    if (photoUrl != null && photoUrl.isNotEmpty) {
                      return CachedNetworkImage(
                        imageUrl: photoUrl,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Center(
                              child: Text(
                                item.name.isNotEmpty
                                    ? item.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                        errorWidget:
                            (context, url, error) => Center(
                              child: Text(
                                item.name.isNotEmpty
                                    ? item.name[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                      );
                    }
                    return Center(
                      child: Text(
                        item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 18,
                        ),
                      ),
                    );
                  }(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      item.position,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    if (item.unit.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.unit,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.time,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
