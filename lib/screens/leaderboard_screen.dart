import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/performance_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final PerformanceService _performanceService = PerformanceService();
  bool isLoading = true;
  List<Map<String, dynamic>> podium = [];
  List<Map<String, dynamic>> others = [];
  Map<String, dynamic>? myRankData;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    final data = await _performanceService.getLeaderboard();
    if (mounted) {
      if (data != null) {
        setState(() {
          podium = List<Map<String, dynamic>>.from(data['podium'] ?? []);
          others = List<Map<String, dynamic>>.from(data['others'] ?? []);
          myRankData = data['my_rank'];
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          'Papan Peringkat Kinerja',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : (podium.isEmpty && others.isEmpty)
              ? _buildEmptyState()
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (podium.isNotEmpty) _buildPodium(),
                          const SizedBox(height: 32),
                          Text(
                            'Peringkat Pegawai',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildRankList(),
                        ],
                      ),
                    ),
                  ),
                  if (myRankData != null) _buildMyRankFixed(),
                ],
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Leaderboard belum tersedia',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    // We expect at least 1-3 items here.
    // Handling cases where podium might have fewer than 3 items
    final Map<String, dynamic>? first = podium.isNotEmpty ? podium[0] : null;
    final Map<String, dynamic>? second = podium.length > 1 ? podium[1] : null;
    final Map<String, dynamic>? third = podium.length > 2 ? podium[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          if (second != null)
            _buildPodiumItem(
              name: second['full_name'] ?? 'Pegawai',
              points: '${second['total_points']} Poin',
              rank: '2',
              avatarColor: Colors.grey[200]!,
              imageSize: 70,
              isFirst: false,
              isMe: second['is_me'] == true,
            )
          else
            const SizedBox(width: 80),

          // 1st Place
          if (first != null)
            _buildPodiumItem(
              name: first['full_name'] ?? 'Pegawai',
              points: '${first['total_points']} Poin',
              rank: '1',
              avatarColor: const Color(0xFFFFD700),
              imageSize: 90,
              isFirst: true,
              isMe: first['is_me'] == true,
            )
          else
            const SizedBox(width: 80),

          // 3rd Place
          if (third != null)
            _buildPodiumItem(
              name: third['full_name'] ?? 'Pegawai',
              points: '${third['total_points']} Poin',
              rank: '3',
              avatarColor: const Color(0xFFCD7F32),
              imageSize: 70,
              isFirst: false,
              isMe: third['is_me'] == true,
            )
          else
            const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required String name,
    required String points,
    required String rank,
    required Color avatarColor,
    required double imageSize,
    bool isFirst = false,
    bool isMe = false,
  }) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isMe
                          ? const Color(0xFF3B82F6)
                          : (isFirst
                              ? const Color(0xFFFFD700)
                              : Colors.transparent),
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: imageSize / 2,
                backgroundColor:
                    isMe ? const Color(0xFF3B82F6) : Colors.grey[100],
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: imageSize * 0.4,
                    color: isMe ? Colors.white : Colors.grey[400],
                  ),
                ),
              ),
            ),
            if (isFirst)
              Positioned(
                top: -12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD700),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 14),
                ),
              ),
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color:
                      isFirst
                          ? const Color(0xFFFFD700)
                          : (isMe
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  rank,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color:
                        (isFirst || isMe)
                            ? Colors.white
                            : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 80,
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isMe ? const Color(0xFF3B82F6) : const Color(0xFF1E293B),
            ),
          ),
        ),
        Text(
          points,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3B82F6),
          ),
        ),
      ],
    );
  }

  Widget _buildRankList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: others.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = others[index];
        final rank = item['rank'] ?? (index + 4);
        final bool isMe = item['is_me'] == true;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border:
                isMe
                    ? Border.all(color: const Color(0xFF3B82F6), width: 1)
                    : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Text(
                  rank.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        (rank as int) <= 3
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    isMe ? const Color(0xFF3B82F6) : Colors.grey[100],
                child: Text(
                  (item['full_name'] as String?)?[0].toUpperCase() ?? '?',
                  style: GoogleFonts.poppins(
                    color: isMe ? Colors.white : Colors.grey[400],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['full_name'] ?? 'Pegawai',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color:
                            isMe
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'ID: ${item['id']}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${item['total_points']} Poin',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMyRankFixed() {
    if (myRankData == null) return const SizedBox.shrink();

    final rank = myRankData!['rank'];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(
                    (myRankData!['full_name'] as String?)?[0].toUpperCase() ??
                        '?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD700),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  rank.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Peringkat Saya',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  myRankData!['full_name'] ?? 'Nama Saya',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                myRankData!['total_points'].toString(),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3B82F6),
                  height: 1.1,
                ),
              ),
              Text(
                'POIN TOTAL',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
