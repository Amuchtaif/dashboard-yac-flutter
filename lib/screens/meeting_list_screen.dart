import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/meeting_model.dart';
import '../services/permission_service.dart';
import 'create_meeting_screen.dart';
import 'meeting_detail_screen.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  int _selectedTabIndex = 0; // 0: Mendatang, 1: Selesai
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  int? _userId;

  // Permission state
  bool _canCreateMeeting = false;
  final PermissionService _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');

    // Load permissions - first from cache, then fetch fresh from API
    await _permissionService.loadFromCache();

    // Also fetch fresh permissions if userId is available
    if (_userId != null) {
      await _permissionService.fetchPermissions(_userId!);
    }

    if (mounted) {
      setState(() {
        _canCreateMeeting = _permissionService.canCreateMeeting;
      });
      debugPrint('📋 MeetingListScreen: canCreateMeeting = $_canCreateMeeting');
    }

    if (_userId != null) {
      _fetchMeetings();
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMeetings() async {
    setState(() => _isLoading = true);
    // Mock or specific endpoint
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/get_meetings.php?user_id=$_userId",
    );

    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'];
          if (mounted) {
            setState(() {
              _meetings = list.map((e) => Meeting.fromJson(e)).toList();
              _isLoading = false;
            });
          }
        } else {
          // If API fails or not exists, show mock for UI demo if acceptable,
          // but cleaner to show empty state with error message.
          // For this task, I will stick to empty state if fetch fails to avoid confusion.
          debugPrint("Fetch Meetings Failed: ${data['message']}");
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching meetings: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Meeting> get _filteredMeetings {
    final now = DateTime.now();

    return _meetings.where((m) {
      // Parse timestamp rapat
      DateTime? meetingEnd;
      try {
        // Gabungkan date dan endTime
        final datePart = DateTime.parse(m.date);
        final timeParts = m.endTime.split(':');
        final endHour = int.parse(timeParts[0]);
        final endMinute = int.parse(timeParts[1]);

        meetingEnd = DateTime(
          datePart.year,
          datePart.month,
          datePart.day,
          endHour,
          endMinute,
        );
      } catch (e) {
        // Fallback jika format error, gunakan status dari API
        meetingEnd = null;
      }

      final bool isFinished =
          meetingEnd != null
              ? now.isAfter(meetingEnd)
              : (m.status.toLowerCase() == 'finished');

      // Tab 0: Mendatang (Not Finished)
      // Tab 1: Selesai (Finished)
      if (_selectedTabIndex == 0) {
        return !isFinished;
      } else {
        return isFinished;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light grey background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black87,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Daftar Rapat",
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Kelola agenda strategis Anda hari ini.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  _buildTabButton("Mendatang", 0),
                  const SizedBox(width: 12),
                  _buildTabButton("Selesai", 1),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // List
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredMeetings.isEmpty
                      ? Center(
                        child: Text(
                          "Tidak ada rapat ${_selectedTabIndex == 0 ? 'mendatang' : 'selesai'}",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        itemCount: _filteredMeetings.length,
                        itemBuilder: (context, index) {
                          return _buildMeetingCard(_filteredMeetings[index]);
                        },
                      ),
            ),
          ],
        ),
      ),
      // Dynamic UI: Only show FAB when user has permission to create meeting
      floatingActionButton:
          _canCreateMeeting
              ? FloatingActionButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateMeetingScreen(),
                    ),
                  );
                  _fetchMeetings(); // Refresh on return
                },
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              )
              : null, // Hide FAB when user doesn't have permission
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.05),
                      blurRadius: 4,
                    ),
                  ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingCard(Meeting meeting) {
    final isOnline = meeting.type.toLowerCase() == 'online';
    const primaryColor = Color(0xFF3B82F6);
    const bgGradient = [Color(0xFF3B82F6), Color(0xFF60A5FA)];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeetingDetailScreen(meeting: meeting),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Gradient Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bgGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isOnline
                          ? Icons.videocam_rounded
                          : Icons.location_on_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOnline ? 'Rapat Online' : 'Rapat Offline',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meeting.formattedDate,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Time badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          meeting.startTime.length >= 5
                              ? meeting.startTime.substring(0, 5)
                              : meeting.startTime,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    meeting.title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Location/Link info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isOnline ? Icons.link_rounded : Icons.place_rounded,
                            size: 18,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOnline ? 'Link Meeting' : 'Lokasi',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isOnline
                                    ? (meeting.link ?? 'Belum tersedia')
                                    : (meeting.location ?? 'Belum ditentukan'),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isOnline
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFF374151),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bottom row: Creator info & Detail button
                  Row(
                    children: [
                      // Creator info
                      if (meeting.creatorName != null) ...[
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366F1),
                                const Color(0xFF8B5CF6),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              meeting.creatorName!.isNotEmpty
                                  ? meeting.creatorName![0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Diselenggarakan oleh',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              ),
                              Text(
                                meeting.creatorName!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF374151),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const Spacer(),
                      ],

                      // Detail button
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: bgGradient),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          MeetingDetailScreen(meeting: meeting),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Lihat Detail',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
