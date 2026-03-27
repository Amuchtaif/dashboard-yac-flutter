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
        if (v.namaKategori.toLowerCase() == 'ringan') {
          ringan++;
        } else if (v.namaKategori.toLowerCase() == 'sedang') {
          sedang++;
        } else if (v.namaKategori.toLowerCase() == 'berat') {
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
    if (v.namaKategori.toLowerCase() == 'berat') {
      severityColor = Colors.red;
    } else if (v.namaKategori.toLowerCase() == 'sedang') {
      severityColor = Colors.orange;
    }

    return Container(
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
                  v.namaKategori,
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
              TextButton(
                onPressed: () => _showViolationDetail(v),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Lihat Detail',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
          ),
        ],
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddViolationSheet(),
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
                Text(_violation?.namaKategori ?? '', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.bold)),
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

class AddViolationSheet extends StatefulWidget {
  const AddViolationSheet({super.key});

  @override
  State<AddViolationSheet> createState() => _AddViolationSheetState();
}

class _AddViolationSheetState extends State<AddViolationSheet> {
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
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 24),
                  Text('Catat Pelanggaran', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: formState.hasError
                                    ? Border.all(color: Colors.red, width: 1)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _selectedStudent != null
                                          ? '${_selectedStudent!['nama_siswa']} (${_selectedStudent!['kelas'] ?? '-'})'
                                          : 'Pilih Santri',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _selectedStudent != null
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                                ],
                              ),
                            ),
                          ),
                          if (formState.hasError)
                            Padding(
                              padding: const EdgeInsets.only(left: 12, top: 8),
                              child: Text(
                                formState.errorText!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ViolationCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Kategori',
                      filled: true, fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.warning_amber_rounded),
                    ),
                    items: _categories.map((c) => DropdownMenuItem(
                      value: c, 
                      child: Text(c.namaKategori, style: const TextStyle(fontSize: 13))
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    validator: (v) => v == null ? 'Pilih kategori' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deskripsiController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi Pelanggaran',
                      filled: true, fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lokasiController,
                    decoration: InputDecoration(
                      labelText: 'Lokasi',
                      filled: true, fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final dt = await showDatePicker(
                        context: context, 
                        initialDate: _selectedDate, 
                        firstDate: DateTime(2024), 
                        lastDate: DateTime.now()
                      );
                      if (dt != null) setState(() => _selectedDate = dt);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(DateFormat('dd MMMM yyyy').format(_selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE11D48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('Simpan Laporan', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _showStudentPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _StudentSearchSheet(
          students: _students,
          onSelected: (student) {
            setState(() => _selectedStudent = student);
          },
        );
      },
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      final success = await ViolationService.create(
        santriId: _selectedStudent!['id'],
        kategoriId: _selectedCategory!.id,
        deskripsi: _deskripsiController.text,
        tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
        lokasi: _lokasiController.text,
        status: _status,
      );
      
      setState(() => _isSubmitting = false);
      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil disimpan')));
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

class _StudentSearchSheet extends StatefulWidget {
  final List<Map<String, dynamic>> students;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _StudentSearchSheet({
    required this.students,
    required this.onSelected,
  });

  @override
  State<_StudentSearchSheet> createState() => _StudentSearchSheetState();
}

class _StudentSearchSheetState extends State<_StudentSearchSheet> {
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pilih Santri',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Cari nama atau kelas...',
                hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE11D48)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Result count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} santri ditemukan',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // List
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_off_outlined,
                            size: 48, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Santri tidak ditemukan',
                          style: GoogleFonts.poppins(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final s = _filtered[index];
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.1),
                          child: Text(
                            (s['nama_siswa'] ?? '?')[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE11D48),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(
                          s['nama_siswa'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                          widget.onSelected(s);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
