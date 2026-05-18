import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/violation_model.dart';
import '../../services/violation_service.dart';

class PelanggaranScreen extends StatefulWidget {
  const PelanggaranScreen({super.key});

  @override
  State<PelanggaranScreen> createState() => _PelanggaranScreenState();
}

class _PelanggaranScreenState extends State<PelanggaranScreen> {
  List<Violation> _violations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  int _countRingan = 0;
  int _countSedang = 0;
  int _countBerat = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final list = await ViolationService.getList(search: _searchQuery);
      
      // Calculate counts
      int ringan = 0;
      int sedang = 0;
      int berat = 0;
      for (var v in list) {
        if (v.tingkatKeparahan?.toLowerCase() == 'ringan') {
          ringan++;
        } else if (v.tingkatKeparahan?.toLowerCase() == 'sedang') {
          sedang++;
        } else if (v.tingkatKeparahan?.toLowerCase() == 'berat') {
          berat++;
        }
      }

      if (mounted) {
        setState(() {
          _violations = list;
          _countRingan = ringan;
          _countSedang = sedang;
          _countBerat = berat;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildSeverityCard(),
                      const SizedBox(height: 24),
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      _buildRecentViolations(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddViolationModal(),
        backgroundColor: const Color(0xFFE11D48),
        icon: const Icon(Icons.add_moderator_rounded, color: Colors.white),
        label: Text(
          'Catat Pelanggaran',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
            'Kedisiplinan & Pelanggaran',
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onSubmitted: (val) {
          setState(() => _searchQuery = val);
          _fetchData();
        },
        decoration: InputDecoration(
          hintText: 'Cari santri atau deskripsi...',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFE11D48)),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear), 
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  _fetchData();
                }
              ) 
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSeverityCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFE11D48),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem('Ringan', '$_countRingan'),
              _buildStatItem('Sedang', '$_countSedang'),
              _buildStatItem('Berat', '$_countBerat'),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Total Kasus: ${_violations.length}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentViolations() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_violations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.assignment_turned_in_rounded, size: 60, color: Colors.grey.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Belum ada catatan pelanggaran.',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DAFTAR PELANGGARAN',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ..._violations.map((v) => _buildViolationCard(v)),
      ],
    );
  }

  Widget _buildViolationCard(Violation v) {
    Color severityColor = Colors.blue;
    if (v.tingkatKeparahan?.toLowerCase() == 'berat') {
      severityColor = Colors.red;
    } else if (v.tingkatKeparahan?.toLowerCase() == 'sedang') {
      severityColor = Colors.orange;
    }

    return InkWell(
      onTap: () => _showViolationDetail(v),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    v.tingkatKeparahan ?? 'Umum',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: severityColor,
                    ),
                  ),
                ),
                Text(
                  v.tanggalPelanggaran,
                  style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              v.namaSiswa,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              v.deskripsi,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(v.status),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.grey;
    if (status == 'selesai') {
      color = Colors.green;
    } else if (status == 'diproses') {
      color = Colors.orange;
    } else if (status == 'dilaporkan') {
      color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showViolationDetail(Violation v) {
    // Show details and followups
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ViolationDetailSheet(violationId: v.id),
    ).then((_) => _fetchData());
  }

  void _showAddViolationModal() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddViolationPage(),
      ),
    ).then((value) {
      if (value == true) _fetchData();
    });
  }
}

class ViolationDetailSheet extends StatefulWidget {
  final int violationId;
  const ViolationDetailSheet({super.key, required this.violationId});

  @override
  State<ViolationDetailSheet> createState() => _ViolationDetailSheetState();
}

class _ViolationDetailSheetState extends State<ViolationDetailSheet> {
  bool _isLoading = true;
  bool _isOfficer = false;
  Violation? _violation;
  List<ViolationFollowup> _followups = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final result = await ViolationService.getDetail(widget.violationId);
    if (mounted) {
      setState(() {
        _isOfficer = result['is_officer'] ?? false;
        _violation = result['violation'];
        _followups = result['followups'] ?? [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _violation?.namaSiswa ?? '',
                        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                Text('${_violation?.namaKategori} (${_violation?.tingkatKeparahan ?? "Umum"})', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                _buildInfoRow(Icons.event_note, 'Tanggal', _violation?.tanggalPelanggaran ?? '-'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.location_on_outlined, 'Lokasi', _violation?.lokasi ?? '-'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.person_pin_outlined, 'Pelapor', _violation?.pelaporName ?? '-'),
                const SizedBox(height: 24),
                Text('Deskripsi:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Text(_violation?.deskripsi ?? '', style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
                const Divider(height: 48),
                Text('RIWAYAT TINDAK LANJUT', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 16),
                if (_followups.isEmpty)
                  Center(child: Text('Belum ada tindak lanjut', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)))
                else
                  ..._followups.map((f) => _buildFollowupItem(f)),
                if (_isOfficer) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _showAddFollowup,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: Text('Tambah Tindak Lanjut', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label: ', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey)),
        Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFollowupItem(ViolationFollowup f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(f.tanggalTindakan, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold)),
              Text(f.penindakName, style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(f.tindakan, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
          if (f.catatan != null) ...[
            const SizedBox(height: 4),
            Text(f.catatan!, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
          ],
        ],
      ),
    );
  }

  void _showAddFollowup() {
    showDialog(
      context: context,
      builder: (context) => AddFollowupDialog(violationId: widget.violationId),
    ).then((value) {
      if (value == true) _loadDetail();
    });
  }
}

class AddViolationPage extends StatefulWidget {
  const AddViolationPage({super.key});

  @override
  State<AddViolationPage> createState() => _AddViolationPageState();
}

class _AddViolationPageState extends State<AddViolationPage> {
  final _formKey = GlobalKey<FormState>();
  final _deskripsiController = TextEditingController();
  final _lokasiController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  List<Map<String, dynamic>> _students = [];
  List<ViolationCategory> _categories = [];
  Map<String, dynamic>? _selectedStudent;
  ViolationCategory? _selectedCategory;
  final String _status = 'dilaporkan';
  
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    final results = await Future.wait([
      ViolationService.getStudents(),
      ViolationService.getCategories(),
    ]);
    if (mounted) {
      setState(() {
        _students = results[0] as List<Map<String, dynamic>>;
        _categories = results[1] as List<ViolationCategory>;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _deskripsiController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF1F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Catat Pelanggaran',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('SISWA & KATEGORI'),
                  const SizedBox(height: 12),
                  _buildCardContainer([
                    // Field Pilih Santri
                    FormField<Map<String, dynamic>>(
                      validator: (v) => _selectedStudent == null ? 'Pilih santri' : null,
                      builder: (formState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _showStudentPicker(),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: formState.hasError ? Colors.red : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.person_outline, color: Color(0xFFE11D48)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedStudent != null
                                            ? '${_selectedStudent!['nama_siswa']} (${_selectedStudent!['kelas'] ?? '-'})'
                                            : 'Pilih Santri',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: _selectedStudent != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: _selectedStudent != null
                                              ? const Color(0xFF1E293B)
                                              : Colors.grey.shade500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
                                  ],
                                ),
                              ),
                            ),
                            if (formState.hasError)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, top: 8),
                                child: Text(
                                  formState.errorText!,
                                  style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Field Pilih Jenis Pelanggaran
                    FormField<ViolationCategory>(
                      validator: (v) => _selectedCategory == null ? 'Pilih jenis pelanggaran' : null,
                      builder: (formState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => _showCategoryPicker(),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: formState.hasError ? Colors.red : Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFE11D48)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedCategory != null
                                            ? '${_selectedCategory!.namaKategori} (${_selectedCategory!.poin} Poin)'
                                            : 'Pilih Jenis Pelanggaran',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: _selectedCategory != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: _selectedCategory != null
                                              ? const Color(0xFF1E293B)
                                              : Colors.grey.shade500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 22),
                                  ],
                                ),
                              ),
                            ),
                            if (formState.hasError)
                              Padding(
                                padding: const EdgeInsets.only(left: 12, top: 8),
                                child: Text(
                                  formState.errorText!,
                                  style: GoogleFonts.poppins(color: Colors.red.shade700, fontSize: 12),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('DETAIL KEJADIAN'),
                  const SizedBox(height: 12),
                  _buildCardContainer([
                    // Deskripsi Pelanggaran
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        labelText: 'Deskripsi Pelanggaran',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        alignLabelWithHint: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE11D48)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Deskripsi wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    // Lokasi
                    TextFormField(
                      controller: _lokasiController,
                      style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
                      decoration: InputDecoration(
                        labelText: 'Lokasi',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade500, fontSize: 14),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFFE11D48)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFE11D48)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tanggal
                    InkWell(
                      onTap: () async {
                        final dt = await showDatePicker(
                          context: context, 
                          initialDate: _selectedDate, 
                          firstDate: DateTime(2024), 
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFFE11D48),
                                  onPrimary: Colors.white,
                                  onSurface: Color(0xFF1E293B),
                                ),
                              ),
                              child: child!,
                            );
                          }
                        );
                        if (dt != null) setState(() => _selectedDate = dt);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20, color: Color(0xFFE11D48)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                DateFormat('dd MMMM yyyy').format(_selectedDate),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Icon(Icons.edit_calendar_rounded, color: Colors.grey.shade400, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting || _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _isSubmitting 
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Simpan Laporan',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF64748B),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  void _showStudentPicker() async {
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _StudentSearchDialog(students: _students),
    );
    if (selected != null) {
      setState(() => _selectedStudent = selected);
    }
  }

  void _showCategoryPicker() async {
    final selected = await showDialog<ViolationCategory>(
      context: context,
      builder: (context) => _CategorySearchDialog(categories: _categories),
    );
    if (selected != null) {
      setState(() => _selectedCategory = selected);
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final success = await ViolationService.create(
        santriId: int.parse(_selectedStudent!['id'].toString()),
        kategoriId: _selectedCategory!.id,
        deskripsi: _deskripsiController.text,
        tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
        lokasi: _lokasiController.text,
        status: _status,
      );
      
      setState(() => _isSubmitting = false);
      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Laporan berhasil disimpan'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

class AddFollowupDialog extends StatefulWidget {
  final int violationId;
  const AddFollowupDialog({super.key, required this.violationId});

  @override
  State<AddFollowupDialog> createState() => _AddFollowupDialogState();
}

class _AddFollowupDialogState extends State<AddFollowupDialog> {
  final _tindakanController = TextEditingController();
  final _catatanController = TextEditingController();
  String _status = 'diproses';
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah Tindak Lanjut', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tindakanController,
              decoration: const InputDecoration(labelText: 'Tindakan (misal: Ta\'zir)'),
            ),
            TextField(
              controller: _catatanController,
              decoration: const InputDecoration(labelText: 'Catatan tambahan'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Update Status Kasus'),
              items: const [
                DropdownMenuItem(value: 'diproses', child: Text('Diproses')),
                DropdownMenuItem(value: 'selesai', child: Text('Selesai / Tutup Kasus')),
              ],
              onChanged: (val) => setState(() => _status = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
        ),
      ],
    );
  }

  void _save() async {
    if (_tindakanController.text.isEmpty) return;
    setState(() => _isSaving = true);
    final success = await ViolationService.addFollowup(
      pelanggaranId: widget.violationId,
      tindakan: _tindakanController.text,
      catatan: _catatanController.text,
      tanggal: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      status: _status,
    );
    if (success && mounted) {
      Navigator.pop(context, true);
    } else {
      setState(() => _isSaving = false);
    }
  }
}

class _StudentSearchDialog extends StatefulWidget {
  final List<Map<String, dynamic>> students;

  const _StudentSearchDialog({required this.students});

  @override
  State<_StudentSearchDialog> createState() => _StudentSearchDialogState();
}

class _StudentSearchDialogState extends State<_StudentSearchDialog> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.students;
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.students;
      } else {
        _filtered = widget.students.where((s) {
          final name = (s['nama_siswa'] ?? '').toString().toLowerCase();
          final kelas = (s['kelas'] ?? '').toString().toLowerCase();
          return name.contains(q) || kelas.contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Santri',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau kelas...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFE11D48), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE11D48)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Result Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${_filtered.length} santri ditemukan',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_off_outlined,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Santri tidak ditemukan',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final s = _filtered[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.1),
                            child: Text(
                              (s['nama_siswa'] ?? '?')[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE11D48),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          title: Text(
                            s['nama_siswa'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Kelas: ${s['kelas'] ?? '-'}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, s);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySearchDialog extends StatefulWidget {
  final List<ViolationCategory> categories;

  const _CategorySearchDialog({required this.categories});

  @override
  State<_CategorySearchDialog> createState() => _CategorySearchDialogState();
}

class _CategorySearchDialogState extends State<_CategorySearchDialog> {
  final _searchController = TextEditingController();
  List<ViolationCategory> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.categories;
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.categories;
      } else {
        _filtered = widget.categories.where((c) {
          final name = c.namaKategori.toLowerCase();
          final point = c.poin.toString();
          return name.contains(q) || point.contains(q);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.65,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Close Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pilih Jenis Pelanggaran',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Cari jenis pelanggaran atau poin...',
                  hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFE11D48), size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE11D48)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Result Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '${_filtered.length} jenis pelanggaran ditemukan',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: 40, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Jenis pelanggaran tidak ditemukan',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        final c = _filtered[index];
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.1),
                            child: Text(
                              c.poin.toString(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE11D48),
                                fontSize: 11,
                              ),
                            ),
                          ),
                          title: Text(
                            c.namaKategori,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            'Poin Pelanggaran: ${c.poin}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context, c);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
