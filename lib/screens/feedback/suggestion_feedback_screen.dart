import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/suggestion_feedback_model.dart';
import '../../services/suggestion_feedback_service.dart';

class SuggestionFeedbackScreen extends StatefulWidget {
  final int initialTabIndex;
  const SuggestionFeedbackScreen({super.key, this.initialTabIndex = 0});

  @override
  State<SuggestionFeedbackScreen> createState() =>
      _SuggestionFeedbackScreenState();
}

class _SuggestionFeedbackScreenState extends State<SuggestionFeedbackScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SuggestionFeedbackService _service = SuggestionFeedbackService();
  final ImagePicker _picker = ImagePicker();

  // User state
  int _userId = 0;
  String _userName = 'Pengguna';
  String _userDivision = '';
  String _appVersion = '1.0.0';

  // Form State
  FeedbackType _selectedType = FeedbackType.newFeature;
  String _selectedModule = 'Umum';
  FeedbackPriority _selectedPriority = FeedbackPriority.medium;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  File? _attachedImage;
  bool _isSubmitting = false;

  // History State
  bool _isLoadingHistory = true;
  List<SuggestionFeedbackModel> _feedbacks = [];
  String _historyFilter = 'Semua';

  final List<String> _moduleOptions = [
    'Umum',
    'Tahfidz',
    'Keasramaan',
    'Presensi Makan',
    'Presensi Pegawai',
    'Payroll / Gaji',
    'Homeroom / Wali Kelas',
    'Akademik & Nilai',
    'Sarpras & Inventaris',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(_handleTabChange);
    _loadUserInfo();
  }

  void _handleTabChange() {
    if (_tabController.index == 1 && !_tabController.indexIsChanging) {
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final rawUserId = prefs.get('user_id') ??
        prefs.get('userId') ??
        prefs.get('id') ??
        prefs.get('employee_id');
    _userId = rawUserId != null ? int.tryParse(rawUserId.toString()) ?? 0 : 0;
    _userName = prefs.getString('fullName') ??
        prefs.getString('userName') ??
        prefs.getString('name') ??
        'Pengguna';
    _userDivision = prefs.getString('divisionName') ??
        prefs.getString('unitName') ??
        prefs.getString('positionName') ??
        '';

    try {
      final pkg = await PackageInfo.fromPlatform();
      _appVersion = '${pkg.version}+${pkg.buildNumber}';
    } catch (_) {}

    if (mounted) setState(() {});
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final list = await _service.getMyFeedbacks(_userId);
    if (!mounted) return;
    setState(() {
      _feedbacks = list;
      _isLoadingHistory = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _attachedImage = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto/Screenshot',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                ),
                title: Text('Kamera', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFAF5FF),
                  child: Icon(Icons.photo_library_rounded, color: Color(0xFF7C3AED)),
                ),
                title: Text('Galeri Gambar', style: GoogleFonts.poppins(fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    if (title.isEmpty) {
      _showSnackBar('Harap masukkan judul usulan/kendala', isError: true);
      return;
    }

    if (desc.isEmpty) {
      _showSnackBar('Harap berikan penjelasan detail', isError: true);
      return;
    }

    if (_userId <= 0) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final rawUserId = prefs.get('user_id') ??
          prefs.get('userId') ??
          prefs.get('id') ??
          prefs.get('employee_id');
      _userId = rawUserId != null ? int.tryParse(rawUserId.toString()) ?? 0 : 0;
      if (_userId <= 0) {
        _showSnackBar(
          'Sesi login tidak terdeteksi. Silakan coba masuk kembali.',
          isError: true,
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final newFeedback = SuggestionFeedbackModel(
      id: 'fb_${DateTime.now().millisecondsSinceEpoch}',
      userId: _userId,
      userName: _userName,
      userDivision: _userDivision,
      type: _selectedType,
      module: _selectedModule,
      title: title,
      description: desc,
      priority: _selectedPriority,
      attachmentPath: _attachedImage?.path,
      appVersion: _appVersion,
      deviceInfo: Platform.operatingSystem,
      status: FeedbackStatus.pending,
      createdAt: DateTime.now(),
    );

    final result = await _service.submitFeedback(newFeedback);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      _titleController.clear();
      _descController.clear();
      setState(() {
        _attachedImage = null;
        _selectedType = FeedbackType.newFeature;
        _selectedPriority = FeedbackPriority.medium;
        _selectedModule = 'Umum';
      });

      _showSnackBar(result.message);
      await _loadHistory();
      _tabController.animateTo(1); // Pindah ke tab Riwayat
    } else {
      _showSnackBar(result.message, isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Usulan Fitur/Lapor Kendala',
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.edit_note_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Kirim Usulan'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history_rounded, size: 18),
                  const SizedBox(width: 6),
                  const Text('Riwayat Saya'),
                  if (_feedbacks.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_feedbacks.length}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: FORM KIRIM USULAN / LAPOR KENDALA
  // ==========================================

  Widget _buildFormTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Informasi Privasi
          _buildPrivacyNoticeCard(),
          const SizedBox(height: 24),

          // Pilihan Jenis Masukan
          Text(
            'JENIS MASUKAN',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          _buildTypeSelector(),
          const SizedBox(height: 24),

          // Modul Terkait & Tingkat Urgensi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MODUL TERKAIT',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModuleDropdown(),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'URGENSI',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPriorityDropdown(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Judul Usulan / Masalah
          Text(
            'JUDUL USULAN / KENDALA',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Contoh: Tambah filter tanggal di absensi asrama',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: const Icon(Icons.title_rounded, color: Color(0xFF64748B), size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Penjelasan Detail
          Text(
            'DETAIL USULAN ATAU PENJELASAN KENDALA',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            minLines: 4,
            maxLines: 8,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText:
                  'Jelaskan kendala yang dialami atau bagaimana ide fitur baru ini dapat membantu operasional pekerjaan Anda...',
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Lampiran Foto / Screenshot
          Text(
            'LAMPIRAN SCREENSHOT / FOTO (OPSIONAL)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          _buildAttachmentSection(),
          const SizedBox(height: 28),

          // Metadata Info Badge Otomatis
          _buildDeviceInfoBar(),
          const SizedBox(height: 24),

          // Tombol Kirim
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _isSubmitting ? 'Mengirim Masukan...' : 'Kirim Usulan & Masukan',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildPrivacyNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_rounded, color: Color(0xFF2563EB), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usulan Bersifat Privat',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Setiap usulan fitur dan laporan kendala hanya dapat dibaca oleh Anda dan Tim IT/Manajemen. Identitas Anda dijaga aman.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF3B82F6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: FeedbackType.newFeature,
                title: 'Fitur Baru',
                desc: 'Ide baru di app',
                icon: Icons.lightbulb_rounded,
                color: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                type: FeedbackType.improvement,
                title: 'Peningkatan',
                desc: 'Perbaikan fitur',
                icon: Icons.speed_rounded,
                color: const Color(0xFFD97706),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTypeCard(
                type: FeedbackType.bugReport,
                title: 'Lapor Kendala',
                desc: 'Error atau bug',
                icon: Icons.bug_report_rounded,
                color: const Color(0xFFE11D48),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTypeCard(
                type: FeedbackType.generalFeedback,
                title: 'Saran Umum',
                desc: 'Kritik & saran',
                icon: Icons.chat_bubble_outline_rounded,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeCard({
    required FeedbackType type,
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () => setState(() => _selectedType = type),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
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
    );
  }

  Widget _buildModuleDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedModule,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E293B)),
          items: _moduleOptions.map((mod) {
            return DropdownMenuItem<String>(
              value: mod,
              child: Text(mod, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedModule = val);
          },
        ),
      ),
    );
  }

  Widget _buildPriorityDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FeedbackPriority>(
          value: _selectedPriority,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF1E293B)),
          items: [
            DropdownMenuItem(
              value: FeedbackPriority.low,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF64748B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Rendah'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: FeedbackPriority.medium,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Sedang'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: FeedbackPriority.high,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Mendesak'),
                ],
              ),
            ),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedPriority = val);
          },
        ),
      ),
    );
  }

  Widget _buildAttachmentSection() {
    if (_attachedImage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                _attachedImage!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Screenshot terlampir',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    _attachedImage!.path.split('/').last.split('\\').last,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
              tooltip: 'Hapus lampiran',
              onPressed: () => setState(() => _attachedImage = null),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: _showImageSourceDialog,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFCBD5E1),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unggah Screenshot atau Foto Bukti',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Maksimal 1 gambar (Kamera atau Galeri)',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceInfoBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Disertakan otomatis: Versi $_appVersion • Pengirim: $_userName (${_userDivision.isEmpty ? "Pegawai" : _userDivision})',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: RIWAYAT USULAN & LAPOR KENDALA
  // ==========================================

  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredList = _historyFilter == 'Semua'
        ? _feedbacks
        : _feedbacks.where((f) {
            if (_historyFilter == 'Menunggu') {
              return f.status == FeedbackStatus.pending ||
                  f.status == FeedbackStatus.reviewed;
            }
            if (_historyFilter == 'Diproses') {
              return f.status == FeedbackStatus.inProgress;
            }
            if (_historyFilter == 'Selesai') {
              return f.status == FeedbackStatus.completed;
            }
            if (_historyFilter == 'Ditunda') {
              return f.status == FeedbackStatus.rejected;
            }
            return true;
          }).toList();

    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: Column(
        children: [
          // Filter status chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Semua'),
                const SizedBox(width: 8),
                _buildFilterChip('Menunggu'),
                const SizedBox(width: 8),
                _buildFilterChip('Diproses'),
                const SizedBox(width: 8),
                _buildFilterChip('Selesai'),
                const SizedBox(width: 8),
                _buildFilterChip('Ditunda'),
              ],
            ),
          ),
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyHistoryState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(filteredList[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _historyFilter == label;

    return InkWell(
      onTap: () => setState(() => _historyFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inbox_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Usulan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Usulan fitur atau laporan kendala yang Anda kirim akan muncul di sini beserta status tanggapannya.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Buat Usulan Baru',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(SuggestionFeedbackModel item) {
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _showDetailBottomSheet(item),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Baris 1: Tipe Masukan & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.typeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(item.typeIcon, size: 13, color: item.typeColor),
                          const SizedBox(width: 4),
                          Text(
                            item.typeLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: item.statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: item.statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.statusLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: item.statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Judul
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),

                // Cuplikan Deskripsi
                Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Footer: Modul & Tanggal
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Modul: ${item.module}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      dateFormat.format(item.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),

                // Kotak Balasan Admin (Jika ada)
                if (item.adminNotes != null && item.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_user_rounded,
                              size: 15,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.adminName ?? 'Tanggapan Manajemen/IT',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.adminNotes!,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF166534),
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailBottomSheet(SuggestionFeedbackModel item) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy HH:mm', 'id_ID');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(ctx).padding.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Status Badge & Tipe
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.typeBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(item.typeIcon, size: 14, color: item.typeColor),
                          const SizedBox(width: 6),
                          Text(
                            item.typeLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: item.typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: item.statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        item.statusLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: item.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Judul
                Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),

                // Meta Info
                Text(
                  'Diajukan pada ${dateFormat.format(item.createdAt)} • Modul: ${item.module}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const Divider(height: 28, color: Color(0xFFE2E8F0)),

                // Deskripsi Lengkap
                Text(
                  'PENJELASAN USULAN / KENDALA',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF334155),
                    height: 1.5,
                  ),
                ),

                // Lampiran Gambar jika ada
                if (item.attachmentPath != null && item.attachmentPath!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'LAMPIRAN SCREENSHOT',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(item.attachmentPath!),
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(16),
                        color: const Color(0xFFF1F5F9),
                        child: Text(
                          'Gambar lampiran lokal',
                          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ],

                // Balasan Admin
                if (item.adminNotes != null && item.adminNotes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 18,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.adminName ?? 'Tanggapan Manajemen/IT',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.adminNotes!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF166534),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
