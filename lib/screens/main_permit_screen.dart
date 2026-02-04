import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'permit_screen.dart'; // Pastikan file ini ada
import '../config/api_config.dart';

class MainPermitScreen extends StatefulWidget {
  const MainPermitScreen({super.key});

  @override
  State<MainPermitScreen> createState() => _MainPermitScreenState();
}

class _MainPermitScreenState extends State<MainPermitScreen> {
  // Key to refresh MyPermitsTab from parent
  final GlobalKey<_MyPermitsTabState> _myPermitsKey = GlobalKey();

  // Key to refresh ApprovalsTab from parent (Optional)
  final GlobalKey<_ApprovalsTabState> _approvalsKey = GlobalKey();

  int? _positionLevel;
  bool _isLoadingLevel = true;

  @override
  void initState() {
    super.initState();
    _checkUserLevel();
  }

  Future<void> _checkUserLevel() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _positionLevel = prefs.getInt(
        'positionLevel',
      ); // Pastikan key ini sesuai saat login
      _isLoadingLevel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLevel) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Logic: Level 1, 2, 3 dianggap Manager (Bisa Approve)
    final bool isManager = _positionLevel != null && _positionLevel! <= 3;

    // --- NON-MANAGER VIEW (List Only) ---
    if (!isManager) {
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
        body: MyPermitsTab(key: _myPermitsKey),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PermitScreen()),
            );
            _myPermitsKey.currentState?._loadData();
          },
          backgroundColor: Colors.blueAccent,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }

    // --- MANAGER VIEW (Tabs) ---
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Perizinan",
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: TabBar(
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blueAccent,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: [
              Tab(
                icon: const Icon(Icons.assignment_ind),
                text: _positionLevel == 1 ? "Izin Semua" : "Izin Saya",
              ),
              const Tab(icon: Icon(Icons.how_to_reg), text: "Persetujuan"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MyPermitsTab(key: _myPermitsKey, positionLevel: _positionLevel),
            ApprovalsTab(key: _approvalsKey),
          ],
        ),
        floatingActionButton:
            _positionLevel == 1
                ? null
                : FloatingActionButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PermitScreen(),
                      ),
                    );
                    // Refresh MyPermitsTab after returning
                    _myPermitsKey.currentState?._loadData();
                  },
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
      ),
    );
  }
}

// ============================================================================
// TAB 1: MY PERMITS (IZIN SAYA)
// ============================================================================

class MyPermitsTab extends StatefulWidget {
  final int? positionLevel;
  const MyPermitsTab({super.key, this.positionLevel});

  @override
  State<MyPermitsTab> createState() => _MyPermitsTabState();
}

class _MyPermitsTabState extends State<MyPermitsTab> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Pending', 'Approved', 'Rejected'];

  List<dynamic> _permits = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null && mounted) {
      _fetchPermits(userId.toString());
    } else if (mounted) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'User ID not found.';
      });
    }
  }

  Future<void> _fetchPermits(String userId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Pastikan URL API benar
    // Pass position_level so backend can return all data if level == 1
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/get_permits.php?user_id=$userId&position_level=${widget.positionLevel ?? 99}",
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          if (data['success'] == true) {
            setState(() {
              _permits = (data['data'] as List?) ?? [];
              _isLoading = false;
              _errorMessage = '';
            });
          } else {
            setState(() {
              _errorMessage = data['message'] ?? 'Gagal memuat data';
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Server Error: ${response.statusCode}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal terhubung ke server.";
          _isLoading = false;
        });
        debugPrint("Error Fetch Permit: $e");
      }
    }
  }

  List<dynamic> get _filteredPermits {
    if (_selectedFilter == 'Semua') return _permits;
    return _permits.where((p) {
      String status = (p['status'] ?? '').toString();
      return status.toLowerCase() == _selectedFilter.toLowerCase();
    }).toList();
  }

  // -- Helper Colors --
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
    if (start == end) return _formatDate(start);
    try {
      DateTime d1 = DateTime.parse(start!);
      DateTime d2 = DateTime.parse(end!);
      return "${DateFormat('dd MMM').format(d1)} - ${DateFormat('dd MMM yyyy').format(d2)}";
    } catch (e) {
      return "$start - $end";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
                        showCheckmark: false,
                        label: Text(
                          filter,
                          style: GoogleFonts.poppins(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight:
                                isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() => _selectedFilter = filter);
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

        // List Content
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        Text(
                          "Belum ada data izin",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                  : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPermits.length,
                    itemBuilder: (context, index) {
                      final permit = _filteredPermits[index];
                      String status = (permit['status'] ?? 'Pending');
                      String type = permit['permit_type'] ?? '-';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(
                              color: _getStatusTextColor(status),
                              width: 6,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Admin View (Level 1): Show Employee Info ---
                              if (widget.positionLevel == 1) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        size: 16,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            permit['full_name'] ??
                                                (permit['employee_name'] ??
                                                    'Nama Tidak Tersedia'),
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            permit['unit_name'] ??
                                                (permit['division_name'] ??
                                                    '-'),
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Divider(color: Colors.grey[100], thickness: 1),
                                const SizedBox(height: 12),
                              ],
                              // ------------------------------------------------

                              // Permit Type & Status Code
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          type,
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF263238),
                                          ),
                                        ),
                                        if (widget.positionLevel != 1 &&
                                            permit['reason'] != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            permit['reason'] ?? '',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(status),
                                      borderRadius: BorderRadius.circular(8),
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

                              const SizedBox(height: 16),

                              // Date Range - Enhanced
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      size: 18,
                                      color: Colors.blueAccent[400],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _formatDateRange(
                                        permit['start_date'],
                                        permit['end_date'],
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Footer Info
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Diajukan",
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                      Text(
                                        _formatDate(permit['created_at']),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (permit['approver_name'] != null &&
                                      permit['approver_name']
                                          .toString()
                                          .isNotEmpty)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "Disetujui oleh",
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          Text(
                                            permit['approver_name'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.blue[700],
                                              fontWeight: FontWeight.w600,
                                            ),
                                            textAlign: TextAlign.end,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}

// ============================================================================
// TAB 2: APPROVALS (PERSETUJUAN - MANAGER)
// ============================================================================

class ApprovalsTab extends StatefulWidget {
  const ApprovalsTab({super.key});

  @override
  State<ApprovalsTab> createState() => _ApprovalsTabState();
}

class _ApprovalsTabState extends State<ApprovalsTab> {
  List<dynamic> _approvalList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  Future<void> _loadApprovals() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId != null && mounted) {
      setState(() => _userId = userId.toString());
      _fetchApprovalList(userId.toString());
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchApprovalList(String userId) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final url = Uri.parse(
      "${ApiConfig.baseUrl}/get_approval_list.php?user_id=$userId",
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          if (data['success'] == true) {
            setState(() {
              _approvalList = (data['data'] as List?) ?? [];
              _isLoading = false;
              _errorMessage = '';
            });
          } else {
            setState(() {
              _isLoading = false;
              if (data['message'] != 'No data') {
                _errorMessage = data['message'] ?? 'Gagal memuat data';
              } else {
                _approvalList = []; // Clean list if no data
              }
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = "Server Error: ${response.statusCode}";
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal terhubung ke server.";
          _isLoading = false;
        });
        debugPrint("Error Fetch Approval: $e");
      }
    }
  }

  // --- REVISI UTAMA DI SINI (ACTION PERMIT) ---
  Future<void> _actionPermit(String permitId, String action) async {
    if (_userId == null) return;

    // Set Loading agar user tidak klik berkali-kali
    setState(() => _isLoading = true);

    final url = Uri.parse("${ApiConfig.baseUrl}/action_permit.php");

    try {
      // PERBAIKAN: Gunakan jsonEncode dan Header JSON
      final bodyData = jsonEncode({
        'user_id': _userId, // Kadang dibutuhkan untuk log
        'approver_id':
            _userId, // Wajib sesuai API action_permit.php yg kita buat
        'permit_id': permitId,
        'action': action,
      });

      debugPrint("Sending Action: $bodyData");

      final response = await http
          .post(
            url,
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: bodyData,
          )
          .timeout(const Duration(seconds: 10));

      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Cek dulu apakah body kosong (kadang server PHP error fatal kirim kosong)
        if (response.body.isEmpty) {
          throw Exception("Server mengirim respon kosong.");
        }

        final data = jsonDecode(response.body);

        if (mounted) {
          if (data['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Berhasil: ${action == 'approve' ? 'Disetujui' : 'Ditolak'}",
                ),
                backgroundColor: Colors.green,
              ),
            );
            // Refresh list setelah sukses
            _fetchApprovalList(_userId!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Gagal: ${data['message']}"),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Server Error: ${response.statusCode}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error Aplikasi: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // PENTING: Matikan loading apapun yang terjadi agar tidak stuck
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDateIndo(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      final months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_errorMessage.isNotEmpty && _approvalList.isEmpty) {
      return Center(child: Text(_errorMessage));
    }

    if (_approvalList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.green[200],
            ),
            const SizedBox(height: 8),
            Text(
              "Tidak ada permintaan pending",
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _approvalList.length,
      itemBuilder: (context, index) {
        final item = _approvalList[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER: Avatar + Name + Position
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 1.5),
                    ),
                    child: const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.blueAccent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['employee_name'] ?? 'Nama Karyawan',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        if (item['position_name'] != null &&
                            item['position_name'].toString().isNotEmpty)
                          Text(
                            item['position_name'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        Text(
                          item['unit_name'] ?? (item['division_name'] ?? '-'),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Permit Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Text(
                      item['permit_type'] ?? 'Izin',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(height: 1, color: Colors.black12),
              const SizedBox(height: 16),

              // DATE SECTION
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 18,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${_formatDateIndo(item['start_date'])} - ${_formatDateIndo(item['end_date'])}",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // REASON SECTION
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Alasan:",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "\"${item['reason']}\"",
                      style: GoogleFonts.poppins(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ACTIONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          () => _actionPermit(item['id'].toString(), 'reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text("Tolak"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          () => _actionPermit(item['id'].toString(), 'approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Setujui",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
