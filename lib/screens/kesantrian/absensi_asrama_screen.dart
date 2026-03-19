import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/asrama_model.dart';
import '../../services/asrama_service.dart';

class AbsensiAsramaScreen extends StatefulWidget {
  const AbsensiAsramaScreen({super.key});

  @override
  State<AbsensiAsramaScreen> createState() => _AbsensiAsramaScreenState();
}

class _AbsensiAsramaScreenState extends State<AbsensiAsramaScreen> {
  final AsramaService _service = AsramaService();
  bool _isLoading = true;
  List<Asrama> _daftarAsrama = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchAsrama();
  }

  Future<void> _fetchAsrama() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await _service.getDaftarAsrama(date: dateStr);
      setState(() {
        _daftarAsrama = res;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching asrama: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchAsrama();
    }
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
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: _fetchAsrama,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoBanner(),
                              const SizedBox(height: 24),
                              Text(
                                'PILIH ASRAMA',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF64748B),
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _daftarAsrama.length,
                                itemBuilder: (context, index) {
                                  return _buildAsramaCard(_daftarAsrama[index]);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Absensi Asrama',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, dd MMMM yyyy',
                            'id_ID',
                          ).format(_selectedDate),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    int total = _daftarAsrama.fold(0, (sum, item) => sum + item.totalSantri);
    int hadir = _daftarAsrama.fold(0, (sum, item) => sum + item.hadir);
    double percent = total > 0 ? (hadir / total) : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Kehadiran',
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$hadir / $total Santri',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(percent * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsramaCard(Asrama asrama) {
    bool isCompleted = asrama.sudahAbsen;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isCompleted ? Colors.green : Colors.blue).withValues(
              alpha: 0.08,
            ),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _handleAsramaClick(asrama),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon Indikator
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: (isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6))
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isCompleted
                        ? Icons.verified_rounded
                        : Icons.pending_actions_rounded,
                    color:
                        isCompleted
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                // Nama & Status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asrama.nama.isNotEmpty
                            ? asrama.nama
                            : 'Kamar #${asrama.id}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: (isCompleted
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF3B82F6))
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isCompleted ? 'Selesai' : 'Belum Absen',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color:
                                    isCompleted
                                        ? const Color(0xFF059669)
                                        : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Progress Counter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${asrama.hadir}/${asrama.totalSantri}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color:
                            isCompleted
                                ? const Color(0xFF10B981)
                                : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Santri',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAsramaClick(Asrama asrama) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    if (asrama.sudahAbsen) {
      // Tampilkan list santri
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  DetailAsramaScreen(asrama: asrama, selectedDate: dateStr),
        ),
      ).then((_) => _fetchAsrama());
    } else {
      // Masuk ke layar absensi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => InputAbsensiAsramaScreen(
                asrama: asrama,
                selectedDate: dateStr,
              ),
        ),
      ).then((value) {
        if (value == true) _fetchAsrama();
      });
    }
  }
}

class DetailAsramaScreen extends StatefulWidget {
  final Asrama asrama;
  final String selectedDate;
  const DetailAsramaScreen({
    super.key,
    required this.asrama,
    required this.selectedDate,
  });

  @override
  State<DetailAsramaScreen> createState() => _DetailAsramaScreenState();
}

class _DetailAsramaScreenState extends State<DetailAsramaScreen> {
  final AsramaService _service = AsramaService();
  bool _isLoading = true;
  List<SantriAsrama> _santriList = [];

  @override
  void initState() {
    super.initState();
    _fetchSantri();
  }

  Future<void> _fetchSantri() async {
    final list = await _service.getSantriByAsrama(
      widget.asrama.id,
      date: widget.selectedDate,
    );
    if (!mounted) return;
    setState(() {
      _santriList = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.asrama.nama,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => InputAbsensiAsramaScreen(
                        asrama: widget.asrama,
                        selectedDate: widget.selectedDate,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(
              'Edit',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _santriList.length,
                itemBuilder: (context, index) {
                  final s = _santriList[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFF1F5F9),
                          child: Text(
                            s.nama[0].toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.nama,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                s.kelas,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (s.keterangan != null &&
                                  s.keterangan!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.notes_rounded,
                                        size: 14,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          s.keterangan!,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                            fontStyle: FontStyle.italic,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _getStatusIcon(s.status),
                      ],
                    ),
                  );
                },
              ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'Hadir':
        return const Icon(
          Icons.check_circle,
          color: Color(0xFF10B981),
          size: 24,
        );
      case 'Izin':
        return const Icon(
          Icons.info_rounded,
          color: Color(0xFFF59E0B),
          size: 24,
        );
      case 'Sakit':
        return const Icon(
          Icons.medical_services_rounded,
          color: Color(0xFF3B82F6),
          size: 24,
        );
      default:
        return const Icon(
          Icons.cancel_rounded,
          color: Color(0xFFEF4444),
          size: 24,
        );
    }
  }
}

class InputAbsensiAsramaScreen extends StatefulWidget {
  final Asrama asrama;
  final String selectedDate;
  const InputAbsensiAsramaScreen({
    super.key,
    required this.asrama,
    required this.selectedDate,
  });

  @override
  State<InputAbsensiAsramaScreen> createState() =>
      _InputAbsensiAsramaScreenState();
}

class _InputAbsensiAsramaScreenState extends State<InputAbsensiAsramaScreen> {
  final AsramaService _service = AsramaService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<SantriAsrama> _santriList = [];

  @override
  void initState() {
    super.initState();
    _fetchSantri();
  }

  Future<void> _fetchSantri() async {
    final list = await _service.getSantriByAsrama(
      widget.asrama.id,
      date: widget.selectedDate,
    );
    if (!mounted) return;
    setState(() {
      _santriList = list;
      // Otomatis hadir semua jika belum ada status atau user ingin reset
      for (var s in _santriList) {
        if (s.status == '' || s.status == 'Belum' || s.status == 'null') {
          s.status = 'Hadir';
        }
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Absensi ${widget.asrama.nama}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _santriList.length,
                      itemBuilder: (context, index) {
                        final s = _santriList[index];
                        final bool showNotes = s.status != 'Hadir';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.nama,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          s.kelas,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _buildStatusButton(
                                        'H',
                                        s.status == 'Hadir',
                                        () {
                                          setState(() => s.status = 'Hadir');
                                        },
                                        const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusButton(
                                        'I',
                                        s.status == 'Izin',
                                        () {
                                          setState(() => s.status = 'Izin');
                                        },
                                        const Color(0xFFF59E0B),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusButton(
                                        'S',
                                        s.status == 'Sakit',
                                        () {
                                          setState(() => s.status = 'Sakit');
                                        },
                                        const Color(0xFF3B82F6),
                                      ),
                                      const SizedBox(width: 8),
                                      _buildStatusButton(
                                        'A',
                                        s.status == 'Alfa',
                                        () {
                                          setState(() => s.status = 'Alfa');
                                        },
                                        const Color(0xFFEF4444),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (showNotes) ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: TextEditingController(
                                    text: s.keterangan ?? '',
                                  ),
                                  onChanged: (val) => s.keterangan = val,
                                  style: GoogleFonts.poppins(fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: 'Keterangan (opsional)',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.notes_rounded,
                                      size: 18,
                                      color: Colors.grey.shade400,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  _buildSaveButton(),
                ],
              ),
    );
  }

  Widget _buildStatusButton(
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color color,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 0,
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                    'Simpan Absensi',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    // Validasi ID sebelum kirim
    final invalidStudents = _santriList.where((s) => s.id == 0).toList();
    if (invalidStudents.isNotEmpty) {
      final names = invalidStudents.take(3).map((s) => s.nama).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ID Santri 0 untuk: $names. (Periksa mapping API)'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final result = await _service.submitAbsensi(
      widget.asrama.id,
      _santriList,
      date: widget.selectedDate,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Absensi berhasil disimpan'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal menyimpan absensi'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }
}
