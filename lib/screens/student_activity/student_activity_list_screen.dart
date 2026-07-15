import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/student_activity_provider.dart';
import '../../models/student_activity_model.dart';
import 'student_activity_detail_screen.dart';
import 'student_activity_form_screen.dart';
import 'student_activity_quick_checklist_screen.dart';

class StudentActivityListScreen extends StatefulWidget {
  const StudentActivityListScreen({super.key});

  @override
  State<StudentActivityListScreen> createState() => _StudentActivityListScreenState();
}

class _StudentActivityListScreenState extends State<StudentActivityListScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  int? _selectedStudentId;
  int? _selectedActivityTypeId;
  String? _selectedStatus;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    // Initial fetch
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudentActivityProvider>(context, listen: false);
      provider.clearFilters();
      provider.fetchActivityTypes();
      provider.fetchStudents();
      provider.fetchActivities(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      Provider.of<StudentActivityProvider>(context, listen: false).fetchActivities();
    }
  }

  Future<void> _refresh() async {
    await Provider.of<StudentActivityProvider>(context, listen: false)
        .fetchActivities(refresh: true);
  }

  void _applySearch(String value) {
    final provider = Provider.of<StudentActivityProvider>(context, listen: false);
    provider.setFilters(
      studentId: _selectedStudentId,
      activityTypeId: _selectedActivityTypeId,
      status: _selectedStatus,
      startDate: provider.filterStartDate,
      endDate: provider.filterEndDate,
      search: value,
    );
    provider.fetchActivities(refresh: true);
  }

  void _openFilterBottomSheet() {
    final provider = Provider.of<StudentActivityProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Aktivitas',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedStudentId = null;
                              _selectedActivityTypeId = null;
                              _selectedStatus = null;
                              _selectedDateRange = null;
                            });
                          },
                          child: Text(
                            'Reset',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Student Filter
                    Text(
                      'Siswa',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedStudentId,
                          hint: Text('Pilih Siswa', style: GoogleFonts.poppins(fontSize: 13)),
                          items: [
                            DropdownMenuItem<int>(
                              value: null,
                              child: Text('Semua Siswa', style: GoogleFonts.poppins(fontSize: 13)),
                            ),
                            ...provider.students.map((s) {
                              return DropdownMenuItem<int>(
                                value: int.tryParse(s['id'].toString()),
                                child: Text(
                                  "${s['full_name']} (${s['kelas']})",
                                  style: GoogleFonts.poppins(fontSize: 13),
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setModalState(() => _selectedStudentId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Activity Type Filter
                    Text(
                      'Jenis Aktivitas',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedActivityTypeId,
                          hint: Text('Pilih Jenis Aktivitas', style: GoogleFonts.poppins(fontSize: 13)),
                          items: [
                            DropdownMenuItem<int>(
                              value: null,
                              child: Text('Semua Aktivitas', style: GoogleFonts.poppins(fontSize: 13)),
                            ),
                            ...provider.activityTypes.map((t) {
                              return DropdownMenuItem<int>(
                                value: t.id,
                                child: Text(t.name, style: GoogleFonts.poppins(fontSize: 13)),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setModalState(() => _selectedActivityTypeId = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Status Filter
                    Text(
                      'Status',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedStatus,
                          hint: Text('Pilih Status', style: GoogleFonts.poppins(fontSize: 13)),
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('Semua Status', style: GoogleFonts.poppins(fontSize: 13)),
                            ),
                            DropdownMenuItem<String>(
                              value: 'completed',
                              child: Text('Dilaksanakan', style: GoogleFonts.poppins(fontSize: 13)),
                            ),
                            DropdownMenuItem<String>(
                              value: 'not_completed',
                              child: Text('Tidak Dilaksanakan', style: GoogleFonts.poppins(fontSize: 13)),
                            ),
                            DropdownMenuItem<String>(
                              value: 'excused',
                              child: Text('Berhalangan', style: GoogleFonts.poppins(fontSize: 13)),
                            ),
                          ],
                          onChanged: (val) {
                            setModalState(() => _selectedStatus = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Date Range Filter
                    Text(
                      'Rentang Tanggal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2025),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          initialDateRange: _selectedDateRange,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF009688),
                                  onPrimary: Colors.white,
                                  onSurface: Color(0xFF1E293B),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setModalState(() => _selectedDateRange = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDateRange == null
                                  ? 'Pilih Rentang Tanggal'
                                  : "${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDateRange!.end)}",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _selectedDateRange == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                              ),
                            ),
                            const Icon(Icons.date_range_outlined, color: Color(0xFF64748B), size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009688),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final startDateStr = _selectedDateRange != null
                              ? DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)
                              : null;
                          final endDateStr = _selectedDateRange != null
                              ? DateFormat('yyyy-MM-dd').format(_selectedDateRange!.end)
                              : null;

                          provider.setFilters(
                            studentId: _selectedStudentId,
                            activityTypeId: _selectedActivityTypeId,
                            status: _selectedStatus,
                            startDate: startDateStr,
                            endDate: endDateStr,
                            search: _searchController.text,
                          );
                          provider.fetchActivities(refresh: true);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Terapkan Filter',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pencatatan Aktivitas',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0F2F1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFF009688)),
                ),
                title: Text(
                  'Formulir Standar',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Catat aktivitas untuk satu siswa secara detail.',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentActivityFormScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.fact_check_rounded, color: Colors.orange),
                ),
                title: Text(
                  'Input Cepat (Quick Checklist)',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  'Catat aktivitas rutin secara massal/batch.',
                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StudentActivityQuickChecklistScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981); // Green
      case 'not_completed':
        return const Color(0xFFEF4444); // Red
      case 'excused':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getTypeColor(String type) {
    if (type == 'personal') {
      return const Color(0xFF3B82F6); // Blue
    } else {
      return const Color(0xFF8B5CF6); // Purple
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Aktivitas Siswa',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: _applySearch,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                        hintText: 'Cari nama siswa atau catatan...',
                        hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _openFilterBottomSheet,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF009688),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main list content
          Expanded(
            child: Consumer<StudentActivityProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading && provider.activities.isEmpty) {
                  return _buildSkeletonLoader();
                }

                if (provider.activities.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: const Color(0xFF009688),
                  onRefresh: _refresh,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: provider.activities.length + (provider.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.activities.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF009688),
                              ),
                            ),
                          ),
                        );
                      }

                      final activity = provider.activities[index];
                      return _buildActivityCard(activity);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddOptions,
        backgroundColor: const Color(0xFF009688),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildActivityCard(StudentActivity activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentActivityDetailScreen(activity: activity),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Badge Type
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getTypeColor(activity.activityType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activity.activityType.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _getTypeColor(activity.activityType),
                        ),
                      ),
                    ),

                    // Badge Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(activity.status).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        activity.statusIndonesian,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(activity.status),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Activity Name
                Text(
                  activity.activityName,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),

                // Student Name
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "${activity.studentName} (${activity.studentClass})",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date & Time
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('dd MMM yyyy').format(DateTime.parse(activity.activityDate)),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (activity.startTime != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            "• ${activity.startTime!.substring(0, 5)}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Creator and attachment counts
                    Row(
                      children: [
                        if (activity.attachments.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.image_outlined, size: 12, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  activity.attachments.length.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          activity.creatorName ?? 'Guru',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 60, height: 16, color: const Color(0xFFF1F5F9)),
                    Container(width: 80, height: 16, color: const Color(0xFFF1F5F9)),
                  ],
                ),
                const SizedBox(height: 16),
                Container(width: 150, height: 20, color: const Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Container(width: 200, height: 16, color: const Color(0xFFF1F5F9)),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 100, height: 14, color: const Color(0xFFF1F5F9)),
                    Container(width: 70, height: 14, color: const Color(0xFFF1F5F9)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE0F2F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_activity_outlined,
                size: 56,
                color: Color(0xFF009688),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aktivitas Belum Tersedia',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada aktivitas yang dicatat. Tap tombol tambah (+) di bawah untuk mencatat aktivitas baru.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
