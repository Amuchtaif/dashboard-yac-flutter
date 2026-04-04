import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/perpulangan_model.dart';
import '../../services/perpulangan_service.dart';
import '../../models/asrama_model.dart';
import '../../services/asrama_service.dart';
import '../../services/permission_service.dart';

class IzinSantriScreen extends StatefulWidget {
  final String? initialPermitId;
  const IzinSantriScreen({super.key, this.initialPermitId});

  @override
  State<IzinSantriScreen> createState() => _IzinSantriScreenState();
}

class _IzinSantriScreenState extends State<IzinSantriScreen> {
  final PerpulanganService _service = PerpulanganService();
  bool _isLoading = true;
  PerpulanganStats? _stats;
  List<PerpulanganPermit> _allActivePermits = [];
  List<PerpulanganPermit> _filteredActivePermits = [];
  final TextEditingController _searchController = TextEditingController();
  int? _supervisorId;
  bool _canApprovePermits = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      if (_supervisorId == null) {
        final prefs = await SharedPreferences.getInstance();
        _supervisorId = prefs.getInt('userId');
      }

      // Check permission
      _canApprovePermits = PermissionService().canApprovePermits;

      final supervisorIdToFetch = _canApprovePermits ? 0 : _supervisorId;

      final results = await Future.wait([
        _service.getStats(supervisorId: supervisorIdToFetch),
        _service.getActivePermits(supervisorId: supervisorIdToFetch),
      ]);

      final statsResult = results[0] as PerpulanganStats?;
      final permitsResult = results[1] as List<PerpulanganPermit>;

      if (mounted) {
        setState(() {
          _stats = statsResult;
          // Filter out 'Libur' as requested
          _allActivePermits = permitsResult
              .where((p) => p.category != 'Libur')
              .toList();
          _filterPermits(_searchController.text);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching izin data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterPermits(String query) {
    setState(() {
      if (widget.initialPermitId != null && query.isEmpty) {
        // Mode detail dari notifikasi
        _filteredActivePermits = _allActivePermits
            .where((p) => p.id.toString() == widget.initialPermitId)
            .toList();
      } else if (query.isEmpty) {
        _filteredActivePermits = _allActivePermits;
      } else {
        _filteredActivePermits = _allActivePermits
            .where((p) => p.studentName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: _isLoading && _stats == null
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildHomecomingBanner(),
                            const SizedBox(height: 24),
                            _buildSearchBar(),
                            const SizedBox(height: 24),
                            _buildActivePermissionsList(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _canApprovePermits
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddPermitModal(),
              backgroundColor: const Color(0xFF0D9488),
              icon: const Icon(Icons.add_task_rounded, color: Colors.white),
              label: Text(
                'Buat Izin',
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
            'Izin Santri',
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

  Widget _buildHomecomingBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D9488),
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: CachedNetworkImageProvider('https://www.transparenttextures.com/patterns/cubes.png'),
          opacity: 0.1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SANTRI IZIN / SAKIT',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_stats?.izinCount ?? 0) + (_stats?.sakitCount ?? 0)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Izin: ${_stats?.izinCount ?? 0} | Sakit: ${_stats?.sakitCount ?? 0}',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.assignment_ind_rounded, color: Colors.white, size: 60),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        onChanged: _filterPermits,
        decoration: InputDecoration(
          hintText: 'Cari nama santri...',
          hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF0D9488)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildActivePermissionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DAFTAR IZIN AKTIF',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF64748B),
                letterSpacing: 1,
              ),
            ),
            if (!_isLoading)
              Text(
                '${_filteredActivePermits.length} Santri',
                style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_filteredActivePermits.isEmpty && !_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.info_outline, size: 40, color: Colors.grey.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text(
                    'Tidak ada santri yang sedang izin.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ..._filteredActivePermits.map((p) => _buildPermissionCard(p)),
      ],
    );
  }

  Widget _buildPermissionCard(PerpulanganPermit p) {
    Color categoryColor = const Color(0xFF0D9488);
    if (p.category == 'Sakit') categoryColor = Colors.orange;

    String returnDate = p.endDate;
    try {
      DateTime dt = DateTime.parse(p.endDate);
      returnDate = DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  p.category == 'Sakit'
                      ? Icons.medical_services_rounded
                      : Icons.person_rounded,
                  color: categoryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.studentName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: const Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (p.asrama != null)
                      Text(
                        'Asrama ${p.asrama!}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: const Color(0xFF0D9488),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${p.category}: ${p.reason}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(p.status),
            ],
          ),
          if (_canApprovePermits && (p.status.toUpperCase() == 'PENDING' || p.status.toUpperCase() == 'MENUNGGU')) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleStatusUpdate(p.id, 'Ditolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Tolak', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleStatusUpdate(p.id, 'Disetujui'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Setujui', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else if (!_canApprovePermits && p.status.toUpperCase() == 'DISETUJUI') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showUpdateStatusDialog(p),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Konfirmasi Kembali',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 32, color: Color(0xFFF1F5F9)),
          Row(
            children: [
              const Icon(
                Icons.event_repeat_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Text(
                'Estimasi Kembali:',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                returnDate,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleStatusUpdate(int id, String status) async {
    setState(() => _isLoading = true);
    final res = await _service.updateStatus(id, status);
    if (!mounted) return;
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status berhasil diubah menjadi $status'),
          backgroundColor: Colors.green, // Selalu hijau karena operasinya berhasil
        ),
      );
      _fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal memperbarui status'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label = status.toUpperCase();
    final s = status.toUpperCase();

    switch (s) {
      case 'DISETUJUI':
        bgColor = const Color(0xFFD1FAE5); // Emerald-100
        textColor = const Color(0xFF065F46); // Emerald-800
        break;
      case 'DITOLAK':
        bgColor = const Color(0xFFFFE4E6); // Rose-100
        textColor = const Color(0xFF9F1239); // Rose-800
        break;
      case 'MENUNGGU':
      case 'PENDING':
        bgColor = const Color(0xFFFEF3C7); // Amber-100
        textColor = const Color(0xFF92400E); // Amber-800
        label = 'PENDING';
        break;
      case 'KEMBALI':
        bgColor = const Color(0xFFF1F5F9); // Slate-100
        textColor = const Color(0xFF334155); // Slate-700
        break;
      default:
        bgColor = const Color(0xFFF1F5F9);
        textColor = const Color(0xFF475569);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  void _showUpdateStatusDialog(PerpulanganPermit p) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Konfirmasi Kedatangan', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Apakah santri ${p.studentName} sudah kembali ke asrama?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              final res = await _service.updateStatus(p.id, 'Kembali');
              if (!mounted) return;
              if (res['success'] == true) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Status diperbarui: Santri sudah kembali.')));
                }
                _fetchData();
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal update status'), backgroundColor: Colors.red));
                }
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
            child: Text('Ya, Sudah Kembali', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddPermitModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPermitBottomSheet(supervisorId: _supervisorId),
    ).then((value) {
      if (value == true) _fetchData();
    });
  }
}

class AddPermitBottomSheet extends StatefulWidget {
  final int? supervisorId;
  const AddPermitBottomSheet({super.key, this.supervisorId});

  @override
  State<AddPermitBottomSheet> createState() => _AddPermitBottomSheetState();
}

class _AddPermitBottomSheetState extends State<AddPermitBottomSheet> {
  final PerpulanganService _service = PerpulanganService();
  final AsramaService _asramaService = AsramaService();
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Asrama? _selectedAsrama;
  PerpulanganStudent? _selectedStudent;
  String _category = 'Izin';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  List<Asrama> _asramaList = [];
  List<PerpulanganStudent> _students = [];
  bool _isLoadingAsrama = true;
  bool _isLoadingStudents = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadAsrama();
  }

  Future<void> _loadAsrama() async {
    setState(() => _isLoadingAsrama = true);
    try {
      final list = await _asramaService.getDaftarAsrama();
      if (mounted) {
        setState(() {
          _asramaList = list;
          _isLoadingAsrama = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingAsrama = false);
    }
  }

  Future<void> _loadStudents(int roomId) async {
    setState(() {
      _isLoadingStudents = true;
      _selectedStudent = null;
      _students = [];
    });
    try {
      final list = await _service.getStudents(roomId: roomId, supervisorId: widget.supervisorId);
      if (mounted) {
        setState(() {
          _students = list;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStudents = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Buat Izin / Sakit', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Text('Cari Asrama', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _isLoadingAsrama
                  ? const LinearProgressIndicator()
                  : DropdownButtonFormField<Asrama>(
                      value: _selectedAsrama,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        hintText: _asramaList.isEmpty
                            ? 'Data asrama tidak ditemukan'
                            : 'Pilih asrama...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.home_work_rounded,
                          size: 20,
                          color: Color(0xFF0D9488),
                        ),
                      ),
                      items:
                          _asramaList
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(
                                    a.nama,
                                    style: GoogleFonts.poppins(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (val) {
                        setState(() => _selectedAsrama = val);
                        if (val != null) _loadStudents(val.id);
                      },
                      validator: (v) => v == null ? 'Pilih asrama' : null,
                    ),
              const SizedBox(height: 16),
              if (_selectedAsrama != null) ...[
                Text('Pilih Santri', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                _isLoadingStudents
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<PerpulanganStudent>(
                        value: _selectedStudent,
                        isExpanded: true,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: _students.isEmpty
                              ? 'Data santri tidak ditemukan'
                              : 'Pilih santri...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_search_rounded,
                            size: 20,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                        items:
                            _students
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(
                                      '${s.name} (${s.className})',
                                      style: GoogleFonts.poppins(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            (val) => setState(() => _selectedStudent = val),
                        validator: (v) => v == null ? 'Pilih santri' : null,
                      ),
                const SizedBox(height: 16),
              ],
              Text('Kategori', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: ['Izin', 'Sakit'].map((cat) => Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _category = cat),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _category == cat ? const Color(0xFF0D9488) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(cat, style: GoogleFonts.poppins(color: _category == cat ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13))),
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              Text('Alasan / Keperluan', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                decoration: InputDecoration(
                  hintText: 'Misal: Acara pernikahan kakak',
                  filled: true, fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tgl Mulai', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final dt = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                            if (dt != null) setState(() => _startDate = dt);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [const Icon(Icons.calendar_today, size: 14), const SizedBox(width: 8), Text(DateFormat('dd/MM/yy').format(_startDate))]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tgl Kembali', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () async {
                            final dt = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2030));
                            if (dt != null) setState(() => _endDate = dt);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Row(children: [const Icon(Icons.calendar_today, size: 14), const SizedBox(width: 8), Text(DateFormat('dd/MM/yy').format(_endDate))]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : Text('Simpan Izin', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final res = await _service.submitPermit(
      studentId: _selectedStudent!.id,
      category: _category,
      reason: _reasonController.text,
      startDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(_endDate),
      musrifId: widget.supervisorId,
    );
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (res['success'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perizinan berhasil dikirim'), backgroundColor: Color(0xFF0D9488)));
          Navigator.pop(context, true);
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Gagal mengirim perizinan'), backgroundColor: Colors.red));
        }
      }
    }
  }
}
