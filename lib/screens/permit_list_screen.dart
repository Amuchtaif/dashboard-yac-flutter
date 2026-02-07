import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Import for initializeDateFormatting
import 'package:shared_preferences/shared_preferences.dart';
import 'permit_screen.dart';
import '../config/api_config.dart';

class PermitListScreen extends StatefulWidget {
  const PermitListScreen({super.key});

  @override
  State<PermitListScreen> createState() => _PermitListScreenState();
}

class _PermitListScreenState extends State<PermitListScreen> {
  String _selectedFilter = 'Semua';
  // Note: Filter keys must match what you expect from the API or be mapped accordingly
  final List<String> _filters = ['Semua', 'Pending', 'Approved', 'Rejected'];

  List<dynamic> _permits = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) setState(() {});
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null) {
      _fetchPermits(userId.toString());
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User ID not found. Please login again.';
      });
    }
  }

  Future<void> _fetchPermits(String userId) async {
    // URL API (Change IP if needed)
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/get_permits.php?user_id=$userId",
    );

    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            _permits = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Gagal memuat data';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Server Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
        _isLoading = false;
      });
    }
  }

  // Helper to filter permits based on status
  // Assumes API status returns 'Pending', 'Approved', 'Rejected' (case insensitive check recommended)
  List<dynamic> get _filteredPermits {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    debugPrint('📅 Current filter: Month=$currentMonth, Year=$currentYear');

    // Filter by month first
    final currentMonthPermits =
        _permits.where((p) {
          DateTime? dateToCheck;

          // Prioritize created_at (Submission Date) based on user feedback
          if (p['created_at'] != null &&
              p['created_at'].toString().trim().isNotEmpty) {
            try {
              dateToCheck = DateTime.parse(p['created_at'].toString().trim());
            } catch (e) {
              debugPrint('❌ Failed to parse created_at: ${p['created_at']}');
            }
          }

          // Fallback to start_date if created_at invalid/missing
          if (dateToCheck == null &&
              p['start_date'] != null &&
              p['start_date'].toString().trim().isNotEmpty) {
            try {
              dateToCheck = DateTime.parse(p['start_date'].toString().trim());
            } catch (e) {
              debugPrint('❌ Failed to parse start_date: ${p['start_date']}');
            }
          }

          if (dateToCheck != null) {
            final isMatch =
                dateToCheck.month == currentMonth &&
                dateToCheck.year == currentYear;
            debugPrint(
              '🔍 Permit ID=${p['id']}, Date=$dateToCheck, Month=${dateToCheck.month}, Year=${dateToCheck.year}, Match=$isMatch',
            );
            return isMatch;
          }
          debugPrint('⚠️ Permit ID=${p['id']} has no valid date, excluding.');
          return false;
        }).toList();

    debugPrint(
      '📊 Total permits: ${_permits.length}, After filter: ${currentMonthPermits.length}',
    );

    if (_selectedFilter == 'Semua') return currentMonthPermits;

    return currentMonthPermits.where((p) {
      String status = (p['status'] ?? '').toString();
      return status.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[100]!;
      case 'approved':
        return Colors.green[100]!;
      case 'rejected':
        return Colors.red[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange[800]!;
      case 'approved':
        return Colors.green[800]!;
      case 'rejected':
        return Colors.red[800]!;
      default:
        return Colors.grey[800]!;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateRange(String? start, String? end) {
    if (start == null && end == null) return '-';

    // If only one date or same date
    if (start == end) return _formatDate(start);

    // If different
    try {
      DateTime d1 = DateTime.parse(start!);
      DateTime d2 = DateTime.parse(end!);

      // Example: 24 Okt - 25 Okt 2023
      // Or if same month: 24 - 25 Okt 2023 (Optional optimization, sticking to simple for now)
      return "${DateFormat('dd MMM').format(d1)} - ${DateFormat('dd MMM yyyy').format(d2)}";
    } catch (e) {
      return "$start - $end";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Daftar Izin",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _filters.map((filter) {
                      final bool isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            filter,
                            style: GoogleFonts.poppins(
                              color:
                                  isSelected ? Colors.white : Colors.grey[600],
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedFilter = filter;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color:
                                  isSelected
                                      ? Colors.blueAccent
                                      : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ),

          // Period Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.blueAccent.withValues(alpha: 0.05),
            child: Text(
              "Periode: ${DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now())}",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
              ),
            ),
          ),

          // Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    )
                    : _filteredPermits.isEmpty
                    ? Center(
                      child: Text(
                        "Belum ada data izin",
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredPermits.length,
                      itemBuilder: (context, index) {
                        final permit = _filteredPermits[index];
                        return _buildPermitCard(permit);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Refresh list after returning from add screen
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PermitScreen()),
          );
          _loadData();
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPermitCard(Map<String, dynamic> permit) {
    String status = (permit['status'] ?? 'Pending');
    String type = permit['permit_type'] ?? '-';
    String startDate = permit['start_date'];
    String endDate = permit['end_date'];
    String createdDate =
        permit['created_at'] ?? ''; // Example: 2023-10-22 10:00:00

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF263238),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatusTextColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateRange(startDate, endDate),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey[200], thickness: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Diajukan pada ${_formatDate(createdDate)}",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              GestureDetector(
                onTap: () {
                  // View Detail Action
                },
                child: Row(
                  children: [
                    Text(
                      "Lihat Detail",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
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
