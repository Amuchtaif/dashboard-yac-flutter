import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/tahfidz_repository.dart';
import '../../services/tahfidz_service.dart';
import '../../screens/login_screen.dart';
import './detail_report_semester_screen.dart';

class ReportSemesterScreen extends StatefulWidget {
  const ReportSemesterScreen({super.key});

  @override
  State<ReportSemesterScreen> createState() => _ReportSemesterScreenState();
}

class _ReportSemesterScreenState extends State<ReportSemesterScreen> {
  final TahfidzRepository _repository = TahfidzRepository();
  final TahfidzService _tahfidzService = TahfidzService();

  List<dynamic> _reports = [];
  List<dynamic> _students = [];
  List<dynamic> _halaqahs = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  String? _selectedTahunAjaran = '2023/2024';
  String? _selectedSemester = '1';
  String? _selectedUnit;
  String? _selectedKelas;
  int? _selectedHalaqahId;
  int? _selectedStudentId;

  @override
  void initState() {
    super.initState();
    _fetchMetadata();
    _fetchReports();
  }

  Future<void> _fetchMetadata() async {
    try {
      final studentsList = await _tahfidzService.getStudents();
      final halaqahList = await _tahfidzService.getHalaqahGroups();
      if (mounted) {
        setState(() {
          _students = studentsList;
          _halaqahs = halaqahList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching metadata: $e');
    }
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final filters = {
      if (_selectedTahunAjaran != null) 'tahun_ajaran': _selectedTahunAjaran,
      if (_selectedSemester != null) 'semester': _selectedSemester,
      if (_selectedUnit != null) 'unit': _selectedUnit,
      if (_selectedKelas != null) 'kelas': _selectedKelas,
      if (_selectedHalaqahId != null) 'halaqah_id': _selectedHalaqahId,
      if (_selectedStudentId != null) 'student_id': _selectedStudentId,
    };

    final result = await _repository.getSemesterReport(filters);

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _reports = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (result['message'] != null && result['message'].toString().contains('Unauthorized')) {
          _handleLogout();
        } else {
          setState(() {
            _errorMessage = result['message'] ?? 'Gagal memuat report semester';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _handleLogout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void _confirmCloseSemester() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tutup Semester'),
        content: const Text('Apakah Anda yakin ingin menutup semester ini? Tindakan ini akan membuat snapshot data semester saat ini dan tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              setState(() => _isLoading = true);

              final payload = {
                'tahun_ajaran': _selectedTahunAjaran,
                'semester': _selectedSemester,
              };

              final result = await _repository.closeSemester(payload);

              if (mounted) {
                if (result['success'] == true) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Semester berhasil ditutup dan snapshot telah dibuat.'), backgroundColor: Colors.green),
                  );
                  _fetchReports();
                } else {
                  messenger.showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Gagal menutup semester'), backgroundColor: Colors.red),
                  );
                  setState(() => _isLoading = false);
                }
              }
            },
            child: const Text('Tutup Semester', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Report',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedTahunAjaran = '2023/2024';
                              _selectedSemester = '1';
                              _selectedUnit = null;
                              _selectedKelas = null;
                              _selectedHalaqahId = null;
                              _selectedStudentId = null;
                            });
                          },
                          child: const Text('Reset', style: TextStyle(color: Colors.red)),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedTahunAjaran,
                      decoration: const InputDecoration(labelText: 'Tahun Ajaran', border: OutlineInputBorder()),
                      items: ['2023/2024', '2024/2025', '2025/2026'].map((tahun) {
                        return DropdownMenuItem(value: tahun, child: Text(tahun));
                      }).toList(),
                      onChanged: (val) => setModalState(() => _selectedTahunAjaran = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedSemester,
                      decoration: const InputDecoration(labelText: 'Semester', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('Ganjil (1)')),
                        DropdownMenuItem(value: '2', child: Text('Genap (2)')),
                      ],
                      onChanged: (val) => setModalState(() => _selectedSemester = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: _selectedUnit,
                      decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                      items: ['SD', 'SMP', 'SMA'].map((u) {
                        return DropdownMenuItem(value: u, child: Text(u));
                      }).toList(),
                      onChanged: (val) => setModalState(() => _selectedUnit = val),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      initialValue: _selectedKelas,
                      decoration: const InputDecoration(labelText: 'Kelas', border: OutlineInputBorder(), hintText: 'Contoh: VII-A'),
                      onChanged: (val) => _selectedKelas = val.trim().isEmpty ? null : val.trim(),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: _selectedHalaqahId,
                      decoration: const InputDecoration(labelText: 'Halaqah', border: OutlineInputBorder()),
                      items: _halaqahs.map((h) {
                        return DropdownMenuItem<int>(
                          value: int.tryParse(h['id']?.toString() ?? ''),
                          child: Text(h['group_name'] ?? h['name'] ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => _selectedHalaqahId = val),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<int>(
                      value: _selectedStudentId,
                      decoration: const InputDecoration(labelText: 'Santri', border: OutlineInputBorder()),
                      items: _students.map((student) {
                        return DropdownMenuItem<int>(
                          value: int.tryParse(student['id']?.toString() ?? ''),
                          child: Text(student['nama_siswa'] ?? student['full_name'] ?? student['name'] ?? '-'),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => _selectedStudentId = val),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _fetchReports();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Terapkan Filter', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Semester',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Colors.teal),
            onPressed: _showFilterSheet,
          )
        ],
      ),
      body: Column(
        children: [
          // Close Semester CTA Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.teal.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Tutup semester untuk tahun ajaran $_selectedTahunAjaran semester $_selectedSemester',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton(
                  onPressed: _confirmCloseSemester,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: const Text('Tutup', style: TextStyle(color: Colors.white, fontSize: 11)),
                ),
              ],
            ),
          ),

          // Report List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchReports,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
                                const SizedBox(height: 16),
                                Text(_errorMessage!, textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchReports,
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                                  child: const Text('Coba Lagi'),
                                )
                              ],
                            ),
                          ),
                        )
                      : _reports.isEmpty
                          ? Center(
                              child: Text(
                                'Tidak ada data report semester',
                                style: GoogleFonts.poppins(color: Colors.grey.shade500),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reports.length,
                              itemBuilder: (context, index) {
                                final item = _reports[index];
                                final studentName = item['student_name'] ?? 'Santri';
                                final percentage = double.tryParse(item['percentage_target']?.toString() ?? '0') ?? 0.0;
                                final progress = item['progress_semester']?.toString() ?? '0';
                                final target = item['target_semester']?.toString() ?? '0';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade100),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.01),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DetailReportSemesterScreen(reportData: item),
                                        ),
                                      );
                                    },
                                    title: Text(
                                      studentName,
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Progress: $progress / $target Halaman (${percentage.toStringAsFixed(1)}%)',
                                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: target == '0' ? 0.0 : (percentage / 100.0).clamp(0.0, 1.0),
                                            backgroundColor: Colors.grey.shade100,
                                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                                            minHeight: 4,
                                          ),
                                        )
                                      ],
                                    ),
                                    trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
