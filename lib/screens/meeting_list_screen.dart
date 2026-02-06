import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/meeting_model.dart';
import 'create_meeting_screen.dart';

class MeetingListScreen extends StatefulWidget {
  const MeetingListScreen({super.key});

  @override
  State<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends State<MeetingListScreen> {
  int _selectedTabIndex = 0; // 0: Mendatang, 1: Selesai, 2: Draft
  List<Meeting> _meetings = [];
  bool _isLoading = true;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
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
    // Simple client-side filter logic
    // Or simpler: Just rely on hypothetical status field.

    // Mapping tabs to status:
    // 0 -> upcoming
    // 1 -> finished
    // 2 -> draft

    String targetStatus = 'upcoming';
    if (_selectedTabIndex == 1) targetStatus = 'finished';
    if (_selectedTabIndex == 2) targetStatus = 'draft';

    return _meetings.where((m) {
      // If no explicit status, try to infer from date?
      // For now, let's assume status matches.
      return m.status == targetStatus;
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
                  const SizedBox(width: 12),
                  _buildTabButton("Draft", 2),
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
                          "Tidak ada rapat ${_selectedTabIndex == 0
                              ? 'mendatang'
                              : _selectedTabIndex == 1
                              ? 'selesai'
                              : 'draft'}",
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
      floatingActionButton: FloatingActionButton(
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  meeting.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (meeting.type == 'Online')
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.blue,
                    size: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Time
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                "Tanggal & Waktu",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(
              "${meeting.date} • ${meeting.startTime}",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Location/Link
          Row(
            children: [
              Icon(
                meeting.type == 'Online' ? Icons.link : Icons.location_on,
                size: 16,
                color: const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                meeting.type == 'Online' ? "Link Rapat" : "Lokasi",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, top: 2),
            child: Text(
              meeting.type == 'Online'
                  ? (meeting.link ?? "-")
                  : (meeting.location ?? "-"),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color:
                    meeting.type == 'Online'
                        ? Colors.blue
                        : const Color(0xFF374151),
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Action & Participants placeholder
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Participant circles placeholder
              Flexible(
                child: SizedBox(
                  height: 30,
                  child: Stack(
                    children: List.generate(3, (index) {
                      return Positioned(
                        left: index * 20.0,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to detail?
                },
                child: Row(
                  children: [
                    Text(
                      "Detail",
                      style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
