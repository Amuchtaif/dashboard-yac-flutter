import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/staff_model.dart';
import '../models/meeting_model.dart';
import '../models/employee_group_model.dart';
import '../services/permission_service.dart';

import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _agendaController = TextEditingController();
  final _linkLocationController = TextEditingController();
  final _dateController = TextEditingController();

  // State
  String _selectedType = 'Offline'; // Online / Offline
  List<EmployeeGroup> _selectedGroups = [];
  List<Staff> _selectedEmployees = [];

  // Summary State (calculated from backend preview API)
  int _summaryGroupCount = 0;
  int _summaryIndividualCount = 0;
  int _summaryTotalCount = 0;
  List<dynamic> _resolvedPreviewMembers = [];
  bool _isLoadingSummary = false;

  // Loading & Meta
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  int? _loginUserId;
  int? _loginDepartmentId;

  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndInitialize();
  }

  @override
  void dispose() {
    _agendaController.dispose();
    _linkLocationController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  /// [SECURITY GUARD] Validasi permission sebelum mengizinkan akses ke halaman ini.
  Future<void> _checkPermissionAndInitialize() async {
    final permissionService = PermissionService();
    await permissionService.loadFromCache();

    if (!permissionService.canCreateMeeting) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anda tidak memiliki akses untuk membuat rapat.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
      return;
    }

    await initializeDateFormatting('id_ID', null);
    await _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _loginUserId = prefs.getInt('userId');
        _loginDepartmentId = prefs.getInt('divisionId');
        _isLoadingData = false;
      });
    }
  }

  Future<void> _updateParticipantSummary() async {
    if (_selectedGroups.isEmpty && _selectedEmployees.isEmpty) {
      if (mounted) {
        setState(() {
          _summaryGroupCount = 0;
          _summaryIndividualCount = 0;
          _summaryTotalCount = 0;
          _resolvedPreviewMembers = [];
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoadingSummary = true);
    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/employee_groups/preview.php");
      final body = jsonEncode({
        "group_ids": _selectedGroups.map((g) => g.id).toList(),
        "employee_ids": _selectedEmployees.map((e) => e.id).toList(),
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: body,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final summaryData = data['data'];
          if (mounted) {
            setState(() {
              _summaryTotalCount = summaryData['total'] ?? 0;
              _summaryGroupCount = summaryData['group_count'] ?? 0;
              _summaryIndividualCount = summaryData['individual_count'] ?? 0;
              _resolvedPreviewMembers = summaryData['members'] ?? [];
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error updating participant summary: $e");
    } finally {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _submitMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showSnack("Pilih tanggal rapat.", isError: true);
      return;
    }
    if (_selectedStartTime == null) {
      _showSnack("Pilih waktu mulai rapat.", isError: true);
      return;
    }
    if (_selectedEndTime == null) {
      _showSnack("Pilih waktu selesai rapat.", isError: true);
      return;
    }
    if (_resolvedPreviewMembers.isEmpty) {
      _showSnack("Pilih minimal 1 peserta rapat.", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final int creator = (_loginUserId == null || _loginUserId == 0) ? 1 : _loginUserId!;
    final int department = (_loginDepartmentId == null || _loginDepartmentId == 0) ? 1 : _loginDepartmentId!;

    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedStartTime!.hour,
      _selectedStartTime!.minute,
    );

    final endDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );

    final List<int> finalParticipantIds = _resolvedPreviewMembers
        .map<int>((e) => int.parse(e['id'].toString()))
        .toList();

    final meeting = Meeting(
      title: _agendaController.text,
      type: _selectedType.toLowerCase(),
      link: _selectedType == 'Online' ? _linkLocationController.text : null,
      location: _selectedType == 'Offline' ? _linkLocationController.text : null,
      date: DateFormat('yyyy-MM-dd').format(_selectedDate!),
      startTime: DateFormat('HH:mm:ss').format(startDateTime),
      endTime: DateFormat('HH:mm:ss').format(endDateTime),
      participantIds: finalParticipantIds,
      departmentId: department,
      creatorId: creator,
    );

    try {
      final url = Uri.parse("${ApiConfig.baseUrl}/create_meeting.php");
      final body = jsonEncode(meeting.toJson());
      debugPrint("Sending Payload: $body");

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: body,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          _showSnack("Rapat berhasil dibuat!", isError: false);
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          _showSnack(data['message'] ?? "Gagal membuat rapat", isError: true);
        }
      }
    } catch (e) {
      if (mounted) _showSnack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year, now.month + 1, now.day),
      helpText: 'Pilih Tanggal Rapat',
    );
    if (date == null) return;

    setState(() {
      _selectedDate = date;
      _dateController.text = DateFormat(
        'EEEE, dd MMMM yyyy',
        'id_ID',
      ).format(date);
    });
  }

  Future<void> _pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
      helpText: 'Pilih Waktu Mulai',
    );

    if (time == null) return;

    setState(() {
      _selectedStartTime = time;
      _selectedEndTime ??= TimeOfDay(
        hour: (time.hour + 1) % 24,
        minute: time.minute,
      );
    });
  }

  Future<void> _pickEndTime() async {
    final initialTime = _selectedStartTime != null
        ? TimeOfDay(
            hour: (_selectedStartTime!.hour + 1) % 24,
            minute: _selectedStartTime!.minute,
          )
        : TimeOfDay.now();

    final time = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? initialTime,
      helpText: 'Pilih Waktu Selesai',
    );

    if (time == null) return;

    setState(() {
      _selectedEndTime = time;
    });
  }

  void _showParticipantSelectionBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ParticipantSelectionBottomSheet(
        initialSelectedGroups: _selectedGroups,
        initialSelectedEmployees: _selectedEmployees,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedGroups = List<EmployeeGroup>.from(result['groups']);
        _selectedEmployees = List<Staff>.from(result['employees']);
      });
      _updateParticipantSummary();
    }
  }

  void _showPreviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => PreviewParticipantsDialog(
        members: _resolvedPreviewMembers,
        total: _summaryTotalCount,
        isLoading: _isLoadingSummary,
        onRetry: _updateParticipantSummary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: Text(
          "Formulir Rapat",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul Rapat
                      _buildLabel("JUDUL RAPAT"),
                      TextFormField(
                        controller: _agendaController,
                        decoration: _inputDecoration(
                          "Contoh: Rapat Koordinasi Bulanan",
                        ),
                        validator: (v) => v!.isEmpty ? "Wajib diisi" : null,
                      ),
                      const SizedBox(height: 24),

                      // Tanggal & Waktu
                      _buildLabel("TANGGAL & WAKTU"),
                      InkWell(
                        onTap: _pickDate,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: Colors.grey,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate != null
                                    ? _dateController.text
                                    : "Pilih Tanggal",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: _selectedDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _pickStartTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedStartTime != null
                                            ? "Mulai: ${_selectedStartTime!.format(context)}"
                                            : "Waktu Mulai",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: _selectedStartTime != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _pickEndTime,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _selectedEndTime != null
                                            ? "Selesai: ${_selectedEndTime!.format(context)}"
                                            : "Waktu Selesai",
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: _selectedEndTime != null
                                              ? Colors.black
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Tipe Rapat
                      _buildLabel("TIPE RAPAT"),
                      Row(
                        children: [
                          _buildTypeChip(
                            "Offline",
                            isSelected: _selectedType == 'Offline',
                          ),
                          const SizedBox(width: 12),
                          _buildTypeChip(
                            "Online",
                            isSelected: _selectedType == 'Online',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Link / Location
                      if (_selectedType == 'Online') ...[
                        TextFormField(
                          controller: _linkLocationController,
                          decoration: _inputDecoration(
                            "Link Meeting (Zoom/GMeet)",
                          ).copyWith(
                            prefixIcon: const Icon(
                              Icons.link,
                              color: Colors.blueAccent,
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? "Link wajib diisi" : null,
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _linkLocationController,
                          decoration: _inputDecoration(
                            "Lokasi Ruangan",
                          ).copyWith(
                            prefixIcon: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                            ),
                          ),
                          validator: (v) => v!.isEmpty ? "Lokasi wajib diisi" : null,
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Pilih Peserta Section
                      _buildLabel("PESERTA RAPAT"),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _showParticipantSelectionBottomSheet,
                            icon: const Icon(Icons.add, size: 18, color: Colors.white),
                            label: Text(
                              "Tambah Peserta",
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          if (_selectedGroups.isNotEmpty || _selectedEmployees.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: _showPreviewDialog,
                              icon: const Icon(Icons.people_outline, size: 18, color: Colors.blueAccent),
                              label: Text(
                                "Preview Peserta",
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.blueAccent),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.blueAccent),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Selected Chips Wrap
                      if (_selectedGroups.isNotEmpty || _selectedEmployees.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._selectedGroups.map(
                              (g) => Chip(
                                label: Text(
                                  g.groupName,
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[900]),
                                ),
                                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                                deleteIcon: Icon(Icons.close, size: 14, color: Colors.blue[900]),
                                onDeleted: () {
                                  setState(() {
                                    _selectedGroups.remove(g);
                                  });
                                  _updateParticipantSummary();
                                },
                              ),
                            ),
                            ..._selectedEmployees.map(
                              (e) => Chip(
                                label: Text(
                                  e.name,
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.green[900]),
                                ),
                                backgroundColor: Colors.green.withValues(alpha: 0.1),
                                deleteIcon: Icon(Icons.close, size: 14, color: Colors.green[900]),
                                onDeleted: () {
                                  setState(() {
                                    _selectedEmployees.remove(e);
                                  });
                                  _updateParticipantSummary();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Ringkasan Peserta (Live Summary Panel)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  _isLoadingSummary
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(
                                          "$_summaryGroupCount",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Kelompok",
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 30, color: Colors.grey[300]),
                              Column(
                                children: [
                                  _isLoadingSummary
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(
                                          "$_summaryIndividualCount",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue[800],
                                          ),
                                        ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Individu",
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 30, color: Colors.grey[300]),
                              Column(
                                children: [
                                  _isLoadingSummary
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(
                                          "$_summaryTotalCount",
                                          style: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Total Peserta",
                                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                ],
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
      bottomNavigationBar: _isLoadingData
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitMeeting,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shadowColor: Colors.blueAccent.withValues(alpha: 0.4),
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Buat Rapat",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (_summaryTotalCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "$_summaryTotalCount peserta",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey[400],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Widget _buildTypeChip(String label, {required bool isSelected}) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : Colors.grey.shade200,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== Bottom Sheet Pemilihan Peserta ====================
class ParticipantSelectionBottomSheet extends StatefulWidget {
  final List<EmployeeGroup> initialSelectedGroups;
  final List<Staff> initialSelectedEmployees;

  const ParticipantSelectionBottomSheet({
    super.key,
    required this.initialSelectedGroups,
    required this.initialSelectedEmployees,
  });

  @override
  State<ParticipantSelectionBottomSheet> createState() =>
      _ParticipantSelectionBottomSheetState();
}

class _ParticipantSelectionBottomSheetState
    extends State<ParticipantSelectionBottomSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Local State Selection
  final List<EmployeeGroup> _tempGroups = [];
  final List<Staff> _tempEmployees = [];

  // Pagination & Loading for Tab Kelompok
  final List<EmployeeGroup> _groups = [];
  int _groupPage = 1;
  bool _groupHasMore = true;
  bool _groupLoading = false;
  bool _groupError = false;
  String _groupSearch = "";
  Timer? _groupDebounce;
  final ScrollController _groupScrollController = ScrollController();

  // Pagination & Loading for Tab Karyawan
  final List<Staff> _employees = [];
  int _employeePage = 1;
  bool _employeeHasMore = true;
  bool _employeeLoading = false;
  bool _employeeError = false;
  String _employeeSearch = "";
  Timer? _employeeDebounce;
  final ScrollController _employeeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _tempGroups.addAll(widget.initialSelectedGroups);
    _tempEmployees.addAll(widget.initialSelectedEmployees);

    // Initial loads
    _fetchGroups(isRefresh: true);
    _fetchEmployees(isRefresh: true);

    // Scroll Listeners
    _groupScrollController.addListener(() {
      if (_groupScrollController.position.pixels >=
          _groupScrollController.position.maxScrollExtent - 200) {
        if (!_groupLoading && _groupHasMore && !_groupError) {
          _fetchGroups();
        }
      }
    });

    _employeeScrollController.addListener(() {
      if (_employeeScrollController.position.pixels >=
          _employeeScrollController.position.maxScrollExtent - 200) {
        if (!_employeeLoading && _employeeHasMore && !_employeeError) {
          _fetchEmployees();
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _groupScrollController.dispose();
    _employeeScrollController.dispose();
    _groupDebounce?.cancel();
    _employeeDebounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchGroups({bool isRefresh = false}) async {
    if (_groupLoading) return;
    if (isRefresh) {
      setState(() {
        _groupPage = 1;
        _groupHasMore = true;
        _groups.clear();
        _groupError = false;
      });
    }

    setState(() => _groupLoading = true);

    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/employee_groups/index.php?page=$_groupPage&limit=15&search=${Uri.encodeComponent(_groupSearch)}&is_active=1",
      );

      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];
          final meta = data['meta'];
          final int totalPages = meta != null ? (meta['total_pages'] ?? 1) : 1;

          setState(() {
            _groups.addAll(list.map((e) => EmployeeGroup.fromJson(e)).toList());
            _groupHasMore = _groupPage < totalPages;
            if (_groupHasMore) _groupPage++;
            _groupError = false;
          });
        } else {
          setState(() => _groupError = true);
        }
      } else {
        setState(() => _groupError = true);
      }
    } catch (_) {
      setState(() => _groupError = true);
    } finally {
      setState(() => _groupLoading = false);
    }
  }

  Future<void> _fetchEmployees({bool isRefresh = false}) async {
    if (_employeeLoading) return;
    if (isRefresh) {
      setState(() {
        _employeePage = 1;
        _employeeHasMore = true;
        _employees.clear();
        _employeeError = false;
      });
    }

    setState(() => _employeeLoading = true);

    try {
      final url = Uri.parse(
        "${ApiConfig.baseUrl}/get_employees.php?page=$_employeePage&limit=15&search=${Uri.encodeComponent(_employeeSearch)}",
      );

      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'] ?? [];

          setState(() {
            _employees.addAll(list.map((e) => Staff.fromJson(e)).where((s) {
              final name = s.name.toLowerCase();
              return name != 'admin' && name != 'administrator';
            }).toList());
            // Since meta isn't returning standard paging on get_employees, we assume hasMore is true if list size is exactly the limit (15)
            _employeeHasMore = list.length >= 15;
            if (_employeeHasMore) _employeePage++;
            _employeeError = false;
          });
        } else {
          setState(() => _employeeError = true);
        }
      } else {
        setState(() => _employeeError = true);
      }
    } catch (_) {
      setState(() => _employeeError = true);
    } finally {
      setState(() => _employeeLoading = false);
    }
  }

  void _onGroupSearch(String val) {
    _groupDebounce?.cancel();
    _groupDebounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _groupSearch = val;
      });
      _fetchGroups(isRefresh: true);
    });
  }

  void _onEmployeeSearch(String val) {
    _employeeDebounce?.cancel();
    _employeeDebounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        _employeeSearch = val;
      });
      _fetchEmployees(isRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Pilih Peserta Rapat",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${_tempGroups.length} Kelompok, ${_tempEmployees.length} Individu",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            tabs: const [
              Tab(text: "Kelompok"),
              Tab(text: "Karyawan"),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupTab(),
                _buildEmployeeTab(),
              ],
            ),
          ),

          // Confirmation Bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, {
                        'groups': _tempGroups,
                        'employees': _tempEmployees,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Konfirmasi Peserta",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              onChanged: _onGroupSearch,
              decoration: InputDecoration(
                hintText: "Cari nama kelompok...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: _groupError
              ? _buildErrorState(onRetry: () => _fetchGroups(isRefresh: true))
              : RefreshIndicator(
                  onRefresh: () => _fetchGroups(isRefresh: true),
                  child: _groups.isEmpty && !_groupLoading
                      ? _buildEmptyState("Belum ada kelompok karyawan.")
                      : ListView.builder(
                          controller: _groupScrollController,
                          itemCount: _groups.length + (_groupLoading ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _groups.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final group = _groups[i];
                            final isSelected = _tempGroups.any((g) => g.id == group.id);

                            return _buildGroupCard(group, isSelected);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(EmployeeGroup group, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _tempGroups.removeWhere((g) => g.id == group.id);
          } else {
            _tempGroups.add(group);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (group.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      group.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              activeColor: Colors.blueAccent,
              onChanged: (val) {
                setState(() {
                  if (isSelected) {
                    _tempGroups.removeWhere((g) => g.id == group.id);
                  } else {
                    _tempGroups.add(group);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              onChanged: _onEmployeeSearch,
              decoration: InputDecoration(
                hintText: "Cari nama, divisi, atau unit...",
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // List
        Expanded(
          child: _employeeError
              ? _buildErrorState(onRetry: () => _fetchEmployees(isRefresh: true))
              : RefreshIndicator(
                  onRefresh: () => _fetchEmployees(isRefresh: true),
                  child: _employees.isEmpty && !_employeeLoading
                      ? _buildEmptyState("Tidak ada data karyawan.")
                      : ListView.builder(
                          controller: _employeeScrollController,
                          itemCount: _employees.length + (_employeeLoading ? 1 : 0),
                          itemBuilder: (ctx, i) {
                            if (i == _employees.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final staff = _employees[i];
                            final isSelected = _tempEmployees.any((e) => e.id == staff.id);

                            return _buildEmployeeCard(staff, isSelected);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Staff staff, bool isSelected) {
    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _tempEmployees.removeWhere((e) => e.id == staff.id);
          } else {
            _tempEmployees.add(staff);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : "?",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${staff.division.isNotEmpty ? staff.division : 'Tanpa Divisi'}${staff.unit.isNotEmpty ? ' • ${staff.unit}' : ''}",
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Checkbox(
              value: isSelected,
              activeColor: Colors.blueAccent,
              onChanged: (val) {
                setState(() {
                  if (isSelected) {
                    _tempEmployees.removeWhere((e) => e.id == staff.id);
                  } else {
                    _tempEmployees.add(staff);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState({required VoidCallback onRetry}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
          const SizedBox(height: 8),
          Text(
            "Terjadi kesalahan koneksi.",
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Coba Lagi",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== Preview Participants Dialog ====================
class PreviewParticipantsDialog extends StatelessWidget {
  final List<dynamic> members;
  final int total;
  final bool isLoading;
  final VoidCallback onRetry;

  const PreviewParticipantsDialog({
    super.key,
    required this.members,
    required this.total,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Daftar Peserta Rapat",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "$total Peserta",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : members.isEmpty
                      ? Center(
                          child: Text(
                            "Belum ada peserta dipilih",
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: members.length,
                          itemBuilder: (ctx, i) {
                            final member = members[i];
                            final String name = member['full_name'] ?? member['name'] ?? 'No Name';
                            final String unit = member['unit_name'] ?? '';
                            final String pos = member['position_name'] ?? member['jabatan'] ?? '';

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.blue.withValues(alpha: 0.05),
                                    child: Text(
                                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          "${pos.isNotEmpty ? pos : 'Staf'}${unit.isNotEmpty ? ' • $unit' : ''}",
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Tutup",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
