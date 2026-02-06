import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/staff_model.dart';
import '../models/meeting_model.dart';

import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

class CreateMeetingScreen extends StatefulWidget {
  const CreateMeetingScreen({super.key});

  @override
  State<CreateMeetingScreen> createState() => _CreateMeetingScreenState();
}

class _CreateMeetingScreenState extends State<CreateMeetingScreen> {
  // ... existing variables ...
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _agendaController = TextEditingController();
  final _linkLocationController =
      TextEditingController(); // Reuse for Location/Link
  final _dateController =
      TextEditingController(); // Display format: Ddd, dd MMM • HH:mm

  // State
  String _selectedType = 'Offline'; // Online / Offline
  String _participantMode = 'Karyawan'; // 'Karyawan' or 'Divisi'

  // Data
  List<Staff> _allStaff = [];
  List<Staff> _selectedStaff = [];
  List<dynamic> _divisions = []; // List of {id, name}

  Map<String, dynamic>? _selectedDivision;

  // Loading & Meta
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  int? _loginUserId;
  int? _loginDivisionId;

  DateTime? _selectedDateTime;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginUserId = prefs.getInt('userId');
      _loginDivisionId = prefs.getInt('divisionId');
    });

    // Fetch Staff & Divisions
    // Fetch Staff & Divisions
    await Future.wait([
      _fetchStaff(), // Load ALL staff for global search
      _fetchDivisions(),
    ]);
    setState(() => _isLoadingData = false);
  }

  Future<void> _fetchStaff() async {
    // API Baru: get_employees.php (Main API)
    // Mengambil semua data untuk client-side search yang cepat
    final url = Uri.parse("${ApiConfig.baseUrl}/get_employees.php");
    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'];
          if (mounted) {
            setState(() {
              _allStaff = list.map((e) => Staff.fromJson(e)).toList();
            });
          }
        }
      } else {
        debugPrint("Fetch Employees Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching employees: $e");
    }
  }

  Future<void> _fetchDivisions() async {
    final url = Uri.parse("${ApiConfig.baseUrl}/get_divisions.php");
    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          if (mounted) {
            setState(() {
              // Ensure data is List of Maps
              _divisions = List<Map<String, dynamic>>.from(
                data['data'].map((x) => Map<String, dynamic>.from(x)),
              );
            });
          }
        }
      } else {
        debugPrint("Fetch Divisions Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching divisions: $e");
    }
  }

  // If "Per Divisi" is selected, we might want to fetch all staff for that division
  // and resolve them to IDs when submitting.
  Future<List<int>> _resolveDivisionParticipants(int divisionId) async {
    // Fetch staff for target division
    final url = Uri.parse(
      "${ApiConfig.baseUrl}/get_staff_by_division.php?division_id=$divisionId",
    );
    try {
      final response = await http.get(
        url,
        headers: {'ngrok-skip-browser-warning': 'true'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final List<dynamic> list = data['data'];
          return list.map<int>((e) => int.parse(e['id'].toString())).toList();
        }
      }
    } catch (e) {
      debugPrint("Error resolving division staff: $e");
    }
    return [];
  }

  Future<void> _submitMeeting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDateTime == null) {
      _showSnack("Pilih tanggal & waktu rapat.", isError: true);
      return;
    }

    List<int> finalParticipantIds = [];

    if (_participantMode == 'Karyawan') {
      if (_selectedStaff.isEmpty) {
        _showSnack("Pilih minimal 1 peserta.", isError: true);
        return;
      }
      finalParticipantIds = _selectedStaff.map((e) => e.id).toList();
    } else {
      // Mode Divisi
      if (_selectedDivision == null) {
        _showSnack("Pilih divisi target.", isError: true);
        return;
      }
      setState(() => _isSubmitting = true);
      finalParticipantIds = await _resolveDivisionParticipants(
        int.parse(_selectedDivision!['id'].toString()),
      );
      if (finalParticipantIds.isEmpty) {
        _showSnack("Divisi ini tidak memiliki karyawan.", isError: true);
        setState(() => _isSubmitting = false);
        return;
      }
    }

    setState(() => _isSubmitting = true);

    // Default to 1 if user/division not found (Dev check)
    final int creator =
        (_loginUserId == null || _loginUserId == 0) ? 1 : _loginUserId!;
    final int division =
        (_loginDivisionId == null || _loginDivisionId == 0)
            ? 1
            : _loginDivisionId!;

    final meeting = Meeting(
      title: _agendaController.text,
      type: _selectedType,
      link: _selectedType == 'Online' ? _linkLocationController.text : null,
      location:
          _selectedType == 'Offline' ? _linkLocationController.text : null,
      date: DateFormat('yyyy-MM-dd').format(_selectedDateTime!),
      startTime: DateFormat('HH:mm:ss').format(_selectedDateTime!),
      endTime: DateFormat(
        'HH:mm:ss',
      ).format(_selectedDateTime!.add(const Duration(hours: 1))),
      participantIds: finalParticipantIds,
      divisionId: division,
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

  // --- Date Time Picker (Combined) ---
  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _dateController.text = DateFormat(
        'EEEE, dd MMM • HH:mm',
        'id_ID',
      ).format(_selectedDateTime!);
      // Note: 'id_ID' requires initializeDateFormatting usually, using default if error or just English format if locale not ready
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light bg
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // Allow bg to show
          statusBarIconBrightness: Brightness.dark, // Dark icons
        ),
        title: Text(
          "Formulir Rapat",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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
                        TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          onTap: _pickDateTime,
                          decoration: _inputDecoration(
                            "Pilih Tanggal & Waktu",
                          ).copyWith(
                            suffixIcon: const Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Tipe Rapat (Online/Offline) - Custom Chips
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
                            validator:
                                (v) => v!.isEmpty ? "Link wajib diisi" : null,
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
                            validator:
                                (v) => v!.isEmpty ? "Lokasi wajib diisi" : null,
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Pilih Kategori Peserta
                        _buildLabel("PILIH PESERTA"),
                        Row(
                          children: [
                            _buildModeChip(
                              "Semua Karyawan",
                              'Karyawan',
                            ), // Perorangan
                            const SizedBox(width: 8),
                            _buildModeChip("Per Divisi", 'Divisi'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Dynamic Content based on Mode
                        if (_participantMode == 'Karyawan') ...[
                          InkWell(
                            onTap: () => _showStaffMultiSelect(),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child:
                                        _selectedStaff.isEmpty
                                            ? Text(
                                              "Semua Karyawan, Bidang, Unit",
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey,
                                              ),
                                            )
                                            : Text(
                                              "${_selectedStaff.length} Karyawan Dipilih",
                                              style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                  ),
                                  const Icon(
                                    Icons.add_circle,
                                    color: Colors.blueAccent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_selectedStaff.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                                  _selectedStaff
                                      .map(
                                        (s) => Chip(
                                          label: Text(
                                            s.name,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                            ),
                                          ),
                                          backgroundColor: Colors.blue
                                              .withValues(alpha: 0.1),
                                          deleteIcon: const Icon(
                                            Icons.close,
                                            size: 14,
                                          ),
                                          onDeleted: () {
                                            setState(
                                              () => _selectedStaff.remove(s),
                                            );
                                          },
                                        ),
                                      )
                                      .toList(),
                            ),
                          ],
                        ] else ...[
                          // Per Divisi Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<Map<String, dynamic>>(
                                isExpanded: true,
                                hint: Text(
                                  "Pilih Divisi (Massal)",
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                  ),
                                ),
                                value: _selectedDivision,
                                items:
                                    _divisions.map((div) {
                                      return DropdownMenuItem<
                                        Map<String, dynamic>
                                      >(
                                        value: div,
                                        child: Text(
                                          div['name'],
                                          style: GoogleFonts.poppins(),
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedDivision = val);
                                },
                              ),
                            ),
                          ),
                          if (_selectedDivision != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.blue.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Semua anggota divisi ${_selectedDivision!['name']} akan diundang.",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.blue[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        const SizedBox(height: 40),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitMeeting,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shadowColor: Colors.blueAccent.withValues(
                                alpha: 0.4,
                              ),
                              elevation: 8,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child:
                                _isSubmitting
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : Text(
                                      "Buat Rapat",
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // Custom Widgets
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

  Widget _buildModeChip(String label, String value) {
    bool isSelected = _participantMode == value;
    return GestureDetector(
      onTap: () => setState(() => _participantMode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _showStaffMultiSelect() async {
    final result = await showDialog<List<Staff>>(
      context: context,
      builder:
          (ctx) => StaffMultiSelectDialog(
            allStaff: _allStaff,
            initialSelected: _selectedStaff,
          ),
    );
    if (result != null) {
      setState(() => _selectedStaff = result);
    }
  }
}

// Reuse existing dialog or ensure it's here
class StaffMultiSelectDialog extends StatefulWidget {
  final List<Staff> allStaff;
  final List<Staff> initialSelected;

  const StaffMultiSelectDialog({
    super.key,
    required this.allStaff,
    required this.initialSelected,
  });

  @override
  State<StaffMultiSelectDialog> createState() => _StaffMultiSelectDialogState();
}

class _StaffMultiSelectDialogState extends State<StaffMultiSelectDialog> {
  List<dynamic> _groupedItems = []; // List of String (Header) or Staff
  int _matchingCount = 0;
  final List<Staff> _tempSelected = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tempSelected.addAll(widget.initialSelected);
    _filter("");
  }

  void _filter(String query) {
    setState(() {
      List<Staff> filtered;
      if (query.isEmpty) {
        filtered = List.from(widget.allStaff);
      } else {
        final q = query.toLowerCase();
        filtered =
            widget.allStaff.where((s) {
              return s.name.toLowerCase().contains(q) ||
                  s.division.toLowerCase().contains(q) ||
                  s.unit.toLowerCase().contains(q);
            }).toList();
      }

      // Sort: Division -> Unit -> Name
      filtered.sort((a, b) {
        int cmpDiv = a.division.compareTo(b.division);
        if (cmpDiv != 0) return cmpDiv;
        int cmpUnit = a.unit.compareTo(b.unit);
        if (cmpUnit != 0) return cmpUnit;
        return a.name.compareTo(b.name);
      });

      // Grouping
      _groupedItems.clear();
      String lastGroupKey = "";

      for (var staff in filtered) {
        // Create a composite key for grouping
        // e.g. "Divisi A - Unit B" or just "Divisi A" if no unit, or "No Division"
        String div = staff.division.isEmpty ? "Tanpa Divisi" : staff.division;
        String unit = staff.unit.isEmpty ? "" : " - ${staff.unit}";
        String groupKey = "$div$unit";

        if (groupKey != lastGroupKey) {
          _groupedItems.add(groupKey); // Add Header
          lastGroupKey = groupKey;
        }
        _groupedItems.add(staff); // Add Item
      }
      _matchingCount = filtered.length;
    });
  }

  void _toggleSelection(Staff staff) {
    setState(() {
      if (_tempSelected.any((s) => s.id == staff.id)) {
        _tempSelected.removeWhere((s) => s.id == staff.id);
      } else {
        _tempSelected.add(staff);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar (Visual only)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Pilih Karyawan",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "$_matchingCount Anggota",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Pilih atau hapus anggota untuk undangan rapat.",
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: "Cari nama, divisi, atau unit...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: ListView.builder(
                itemCount: _groupedItems.length,
                itemBuilder: (ctx, i) {
                  final item = _groupedItems[i];

                  if (item is String) {
                    // Header
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Text(
                        item,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                    );
                  } else if (item is Staff) {
                    // Staff Item
                    final staff = item;
                    final isSelected = _tempSelected.any(
                      (s) => s.id == staff.id,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _toggleSelection(staff),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[200],
                              child: Text(
                                staff.name.isNotEmpty
                                    ? staff.name[0].toUpperCase()
                                    : "?",
                                style: GoogleFonts.poppins(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: staff.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (staff.unit.isNotEmpty)
                                          TextSpan(
                                            text: " (Unit ${staff.unit})",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  // Division is redundant if in header, but keeping small if needed,
                                  // or just hiding it since it's in the header.
                                  // User requested: "Info Tambahan: Di sebelah nama karyawan, sekarang tampil nama Unit mereka"
                                  // Since header has "Division - Unit", maybe we don't need row subtitle as much.
                                  // But let's keep it minimal.
                                ],
                              ),
                            ),
                            // Checkbox custom
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isSelected
                                        ? Colors.blueAccent
                                        : Colors.white,
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? Colors.blueAccent
                                          : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child:
                                  isSelected
                                      ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(height: 24),

            // Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _tempSelected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Konfirmasi Peserta",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (_tempSelected.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
