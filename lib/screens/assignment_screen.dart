import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/assignment_service.dart';
import '../models/assignment_model.dart';
import '../services/permission_service.dart';
import 'task_detail_screen.dart';
import 'create_task_screen.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AssignmentService _service = AssignmentService();
  final PermissionService _permissionService = PermissionService();
  List<Assignment> _assignments = [];
  List<Assignment> _createdAssignments = [];
  bool _isLoading = true;
  bool _canCreateAssignment = false;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserAndData();
  }

  Future<void> _loadUserAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? prefs.getInt('user_id');
    debugPrint("📋 ASSIGNMENT SCREEN USER ID: $_userId");

    // Load permissions - first from cache, then fetch fresh from API
    await _permissionService.loadFromCache();
    if (_userId != null) {
      await _permissionService.fetchPermissions(_userId!);
    }

    if (mounted) {
      setState(() {
        _canCreateAssignment = _permissionService.hasPermission(
          'can_create_assignment',
        );
      });
      debugPrint(
        "📋 PERMISSION 'can_create_assignment': $_canCreateAssignment",
      );

      // Rebuild tab controller based on permission
      final tabCount = _canCreateAssignment ? 4 : 3;
      if (_tabController.length != tabCount) {
        _tabController.dispose();
        _tabController = TabController(length: tabCount, vsync: this);
      }
    }

    if (_userId != null) {
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    debugPrint("📋 FETCHING DATA FOR USER: $_userId");

    final data = await _service.getAssignments(_userId!);
    debugPrint("📋 ASSIGNED TASKS COUNT: ${data.length}");

    List<Assignment> created = [];
    if (_canCreateAssignment) {
      created = await _service.getCreatedAssignments(_userId!);
      debugPrint("📋 DELEGATED TASKS COUNT: ${created.length}");
    }

    if (mounted) {
      setState(() {
        _assignments = data;
        _createdAssignments = created;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildStatusCard(),
                        const SizedBox(height: 24),
                        _buildTabSelector(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabContent('pending'),
                        _buildTabContent('ongoing'),
                        _buildTabContent('done'),
                        if (_canCreateAssignment) _buildDelegatedContent(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _canCreateAssignment
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateTaskScreen(),
                    ),
                  );
                  if (result == true) {
                    _fetchData();
                    // Redirect to "Delegasi" tab (index 3)
                    if (_canCreateAssignment) {
                      _tabController.animateTo(3);
                    }
                  }
                },
                backgroundColor: const Color(0xFF3B82F6),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              )
              : null,
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.1),
              elevation: 2,
            ),
          ),
          Text(
            'Daftar Tugas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.1),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final pendingCount =
        _assignments.where((a) => a.status == 'Belum Dimulai').length;
    final ongoingCount =
        _assignments.where((a) => a.status == 'Sedang Dikerjakan').length;
    final doneCount = _assignments.where((a) => a.status == 'Selesai').length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.assignment_turned_in,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RINGKASAN TUGAS',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Menunggu',
                      pendingCount.toString(),
                      Icons.timer_outlined,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Expanded(
                    child: _buildSummaryItem(
                      'Berjalan',
                      ongoingCount.toString(),
                      Icons.play_circle_outline,
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Expanded(
                    child: _buildSummaryItem(
                      'Selesai',
                      doneCount.toString(),
                      Icons.check_circle_outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 54,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: const Color(0xFF3B82F6),
        unselectedLabelColor: const Color(0xFF64748B),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: [
          const Tab(text: 'Menunggu'),
          const Tab(text: 'Berjalan'),
          const Tab(text: 'Selesai'),
          if (_canCreateAssignment) const Tab(text: 'Delegasi'),
        ],
      ),
    );
  }

  Widget _buildTabContent(String type) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filtered =
        _assignments.where((a) {
          if (type == 'pending') return a.status == 'Belum Dimulai';
          if (type == 'ongoing') return a.status == 'Sedang Dikerjakan';
          return a.status == 'Selesai';
        }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada tugas dalam kategori ini',
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final a = filtered[index];

          Color pColor = const Color(0xFFDBEAFE);
          Color pTextColor = const Color(0xFF3B82F6);
          final pUpper = a.priority.toUpperCase();
          if (pUpper.contains('TINGGI')) {
            pColor = const Color(0xFFFEE2E2);
            pTextColor = const Color(0xFFEF4444);
          } else if (pUpper.contains('SEDANG') || pUpper.contains('MENENGAH')) {
            pColor = const Color(0xFFFEF3C7);
            pTextColor = const Color(0xFFD97706);
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildTaskCard(
              id: a.id,
              priority: a.priority.toUpperCase(),
              priorityColor: pColor,
              priorityTextColor: pTextColor,
              date: a.dueDate,
              title: a.title,
              description: a.description,
              assignerName: a.creatorName ?? 'Atasan',
              assignerRole: a.creatorRole ?? 'Supervisor',
              assignerAvatar: a.creatorAvatar,
              progress: a.progress / 100.0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildDelegatedContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_createdAssignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada tugas yang didelegasikan',
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: _createdAssignments.length,
        itemBuilder: (context, index) {
          final a = _createdAssignments[index];

          // Progress based on status
          double progress = a.progress / 100.0;
          Color progressColor = const Color(0xFF3B82F6);
          String progressLabel = 'Progres Tugas';

          if (a.status == 'Belum Dimulai' && a.progress == 0) {
            progressColor = const Color(0xFF94A3B8);
            progressLabel = 'Belum Dimulai';
          } else if (a.status == 'Selesai' || a.progress == 100) {
            progressColor = const Color(0xFF10B981);
            progressLabel = 'Selesai';
          }

          // Priority colors
          Color pColor = const Color(0xFFDBEAFE);
          Color pTextColor = const Color(0xFF3B82F6);
          final pUpper = a.priority.toUpperCase();
          if (pUpper.contains('TINGGI')) {
            pColor = const Color(0xFFFEE2E2);
            pTextColor = const Color(0xFFEF4444);
          } else if (pUpper.contains('SEDANG') || pUpper.contains('MENENGAH')) {
            pColor = const Color(0xFFFEF3C7);
            pTextColor = const Color(0xFFD97706);
          }

          // Status colors
          Color statusColor = const Color(0xFFF1F5F9);
          Color statusTextColor = const Color(0xFF64748B);
          if (a.status == 'Sedang Dikerjakan') {
            statusColor = const Color(0xFFDBEAFE);
            statusTextColor = const Color(0xFF2563EB);
          } else if (a.status == 'Selesai') {
            statusColor = const Color(0xFFDCFCE7);
            statusTextColor = const Color(0xFF166534);
          }

          final String assigneeInitial =
              (a.assigneeName ?? 'U').isNotEmpty
                  ? (a.assigneeName ?? 'U')[0].toUpperCase()
                  : 'U';

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TaskDetailScreen(taskId: a.id),
                        ),
                      );
                      if (result == true) _fetchData();
                    },
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status badge (Priority moved to Positioned)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      a.status.toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusTextColor,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        a.dueDate,
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: 32,
                                  ), // Spacer for priority badge
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Title
                              Text(
                                a.title,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                a.description,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // Progress bar
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              progressLabel,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: progressColor,
                                              ),
                                            ),
                                            Text(
                                              '${(progress * 100).toInt()}%',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: progressColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            backgroundColor: const Color(
                                              0xFFF1F5F9,
                                            ),
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  progressColor,
                                                ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              const SizedBox(height: 16),
                              // Assignee info
                              Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: progressColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      border: Border.all(
                                        color: progressColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 2,
                                      ),
                                      image:
                                          a.assigneeAvatar != null
                                              ? DecorationImage(
                                                image: NetworkImage(
                                                  a.assigneeAvatar!,
                                                ),
                                                fit: BoxFit.cover,
                                              )
                                              : null,
                                    ),
                                    child:
                                        a.assigneeAvatar == null
                                            ? Center(
                                              child: Text(
                                                assigneeInitial,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: progressColor,
                                                ),
                                              ),
                                            )
                                            : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Ditugaskan kepada:",
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF94A3B8),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        Text(
                                          a.assigneeName ?? 'Penerima',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1E293B),
                                          ),
                                        ),
                                        Text(
                                          a.assigneeRole ?? 'Pegawai',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.grey[300],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (a.priority.trim().isNotEmpty)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: pColor,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(24),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: Text(
                                a.priority.toUpperCase(),
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: pTextColor,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard({
    required int id,
    required String priority,
    required Color priorityColor,
    required Color priorityTextColor,
    required String date,
    required String title,
    required String description,
    required String assignerName,
    required String assignerRole,
    String? assignerAvatar,
    required double progress,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskDetailScreen(taskId: id),
                ),
              );
              if (result == true) {
                _fetchData();
              }
            },
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                date,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (progress > 0) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFF3B82F6),
                                      ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF1F5F9),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 2,
                              ),
                              image:
                                  assignerAvatar != null
                                      ? DecorationImage(
                                        image: NetworkImage(assignerAvatar),
                                        fit: BoxFit.cover,
                                      )
                                      : null,
                            ),
                            child:
                                assignerAvatar == null
                                    ? Center(
                                      child: Text(
                                        assignerName.isNotEmpty
                                            ? assignerName[0].toUpperCase()
                                            : 'A',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    )
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Ditugaskan oleh:",
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF94A3B8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  assignerName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  assignerRole,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey[300],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (priority.trim().isNotEmpty)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(24),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        priority,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: priorityTextColor,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
