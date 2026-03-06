import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/assignment_service.dart';
import '../models/assignment_model.dart';

class TaskDetailScreen extends StatefulWidget {
  final int taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final AssignmentService _service = AssignmentService();
  Assignment? _task;
  bool _isLoading = true;
  File? _selectedFile;
  int? _userId;
  int _currentProgress = 0;
  bool _isProgressChanged = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndFetchDetail();
  }

  Future<void> _loadUserAndFetchDetail() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId') ?? prefs.getInt('user_id');
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    final data = await _service.getDetail(widget.taskId);
    if (mounted) {
      setState(() {
        _task = data;
        _currentProgress = data?.progress ?? 0;
        _isProgressChanged = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    setState(() => _isLoading = true);
    final res = await _service.updateProgress(widget.taskId, _currentProgress);
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res['success'] == true || res['status'] == 'success') {
          _isProgressChanged = false;
          // Get updated status from API response
          final newStatus = res['data']?['status'];
          // Pop back with the new status so assignment screen can switch tab
          Navigator.pop(context, newStatus ?? true);
          return;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['message'] ??
                (res['success'] == true
                    ? 'Progress diperbarui'
                    : 'Gagal memperbarui progress'),
          ),
        ),
      );
    }
  }

  Future<void> _updateProgress(double value) async {
    int newProgress = value.toInt();
    setState(() {
      _currentProgress = newProgress;
      _isProgressChanged = _currentProgress != (_task?.progress ?? 0);
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'zip', 'jpg', 'png', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    final res = await _service.updateStatus(widget.taskId, status);
    if (mounted) {
      if (res['success'] == true || res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Status diperbarui')),
        );
        Navigator.pop(context, status);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui status')),
        );
      }
    }
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih berkas terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _service.submitReport(
      taskId: widget.taskId,
      reportNotes: 'Laporan selesai dikerjakan',
      attachment: _selectedFile,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      final bool isSuccess =
          res['success'] == true || res['status'] == 'success';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess
                ? 'Laporan terkirim'
                : (res['message'] ?? 'Gagal mengirim'),
          ),
        ),
      );
      if (isSuccess) {
        Navigator.pop(context, 'Selesai');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Tugas tidak ditemukan')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [_buildMainCard()],
                ),
              ),
            ),
            if (_task!.status != 'Selesai') _buildStickyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Color(0xFF1E293B),
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.1),
              elevation: 1,
            ),
          ),
          Text(
            'Detail Tugas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 48), // Spacer to balance back button
        ],
      ),
    );
  }

  Widget _buildMainCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_task!.priority.isNotEmpty) ...[
                _buildBadge(
                  _task!.priority.toUpperCase(),
                  _task!.priority.toUpperCase().contains('TINGGI')
                      ? const Color(0xFFFFB038)
                      : _task!.priority.toUpperCase().contains('SEDANG')
                      ? const Color(0xFFD97706)
                      : const Color(0xFF4C8CFF),
                  Colors.white,
                ),
                const SizedBox(width: 8),
              ],
              _buildBadge(
                _task!.status.toUpperCase(),
                _task!.status == 'Belum Dimulai'
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF10B981),
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            _task!.title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF94A3B8),
                  ),
                  children: [
                    const TextSpan(text: 'Tenggat: '),
                    TextSpan(
                      text: _task!.dueDate,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Assigners & Assignees Section
          Row(
            children: [
              // Assigner
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PEMBERI TUGAS',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFF1F5F9),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _task!.creatorName ?? 'Atasan',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _task!.creatorPosition ?? 'Supervisor',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: const Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
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
              const SizedBox(width: 16),
              // Assignee
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENERIMA TUGAS',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE2EDFF),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 18,
                            color: Color(0xFF4C8CFF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _task!.assigneeName ?? 'Pegawai',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1E293B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _task!.assigneePosition ?? 'Staff',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: const Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
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
            ],
          ),
          const SizedBox(height: 32),
          // Progress Section
          Text(
            'PROGRESS TUGAS',
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 6,
                    activeTrackColor: const Color(0xFF4C8CFF),
                    inactiveTrackColor: const Color(0xFFEFF6FF),
                    thumbColor: Colors.white,
                    overlayColor: const Color(
                      0xFF4C8CFF,
                    ).withValues(alpha: 0.1),
                    valueIndicatorColor: const Color(0xFF4C8CFF),
                    valueIndicatorTextStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  child: Slider(
                    value: _currentProgress.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 10,
                    label: '$_currentProgress%',
                    onChanged:
                        _userId == _task!.assignedTo ? _updateProgress : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F7FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$_currentProgress%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4C8CFF),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                size: 18,
                color: Color(0xFF4C8CFF),
              ),
              const SizedBox(width: 8),
              Text(
                'Deskripsi Tugas',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _task!.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          _buildSpecialInstruction(),
          const SizedBox(height: 32),
          Text(
            'Unggah Hasil Kerja',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          _buildUploadArea(),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildSpecialInstruction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: Color(0xFF4C8CFF), width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Color(0xFF4C8CFF)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instruksi Khusus',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _task!.specialInstruction ?? 'Tidak ada instruksi khusus.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Task Attachment (from Creator)
        if (_task!.attachment != null && _task!.attachment!.isNotEmpty)
          _buildAttachmentCard(
            title: 'Berkas Pendukung Tugas',
            subtitle: 'Klik untuk melihat berkas dari atasan',
            icon: Icons.folder_open_rounded,
            onTap: () => _openUrl(_task!.attachment),
          ),

        const SizedBox(height: 16),

        // 2. Report Attachment (Result of work)
        if (_task!.reportAttachment != null &&
            _task!.reportAttachment!.isNotEmpty)
          _buildAttachmentCard(
            title: 'Hasil Kerja Terkirim',
            subtitle: 'Klik untuk melihat berkas laporan',
            icon: Icons.task_alt_rounded,
            color: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF166534),
            onTap: () => _openUrl(_task!.reportAttachment),
          )
        else if (_userId == _task!.assignedTo && _task!.status != 'Selesai')
          // Upload area for assignee if not finished
          InkWell(
            onTap: _pickFile,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD1E4FF), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0EDFF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _selectedFile == null
                          ? Icons.cloud_upload_outlined
                          : Icons.check_circle,
                      color: const Color(0xFF4C8CFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFile == null
                        ? 'Klik untuk unggah hasil kerja'
                        : 'Berkas terpilih',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedFile == null
                        ? 'PDF, ZIP, ATAU GAMBAR (MAKS 10MB)'
                        : _selectedFile!.path.split('/').last,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_userId == _task!.createdBy && _task!.status != 'Selesai')
          // Creator view while task is not finished
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.hourglass_empty_rounded,
                  color: Colors.grey[400],
                  size: 40,
                ),
                const SizedBox(height: 12),
                Text(
                  'Menunggu hasil kerja pegawai',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFFF1F7FF),
    Color iconColor = const Color(0xFF4C8CFF),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: iconColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyButton() {
    // If user is the creator, don't show action buttons
    if (_userId == _task!.createdBy) {
      return const SizedBox.shrink();
    }

    if (_task!.status == 'Selesai') {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF166534)),
              const SizedBox(width: 8),
              Text(
                'Tugas Selesai',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF166534),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    String label = 'Kirim Laporan';
    IconData icon = Icons.send_rounded;
    VoidCallback onPressed = _submitReport;

    if (_isProgressChanged) {
      label = 'Update Progres';
      icon = Icons.sync_rounded;
      onPressed = _saveProgress;
    } else if (_task!.status == 'Belum Dimulai') {
      label = 'Terima Tugas';
      icon = Icons.play_arrow_rounded;
      onPressed = () => _updateStatus('Sedang Dikerjakan');
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_userId == _task!.createdBy &&
              _task!.attachment != null &&
              _task!.attachment!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Open URL logic if needed
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Lihat Berkas Lampiran'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B82F6),
                    side: const BorderSide(color: Color(0xFF3B82F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
