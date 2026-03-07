import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/assignment_service.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionController = TextEditingController();
  final AssignmentService _service = AssignmentService();
  DateTime? _selectedDate;
  int? _selectedMemberId;
  String _selectedPriority = 'Biasa';
  bool _isLoading = false;
  bool _isLoadingSubordinates = true;
  int? _userId;

  File? _selectedFile;
  List<Map<String, dynamic>> _subordinates = [];

  final List<String> _priorities = ['Biasa', 'Sedang', 'Tinggi'];

  @override
  void initState() {
    super.initState();
    _loadSubordinates();
  }

  Future<void> _loadSubordinates() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('userId');
    if (_userId != null) {
      final data = await _service.getSubordinates(_userId!);
      if (mounted) {
        setState(() {
          _subordinates = data;
          _isLoadingSubordinates = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoadingSubordinates = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  Future<void> _submitTask() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _selectedDate == null ||
        _selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua data')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    final int? creatorId = prefs.getInt('userId');

    if (creatorId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi telah berakhir, silakan login kembali'),
        ),
      );
      return;
    }

    final service = AssignmentService();
    final res = await service.createAssignment(
      title: _titleController.text,
      description: _descriptionController.text,
      priority: _selectedPriority,
      dueDate:
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
      createdBy: creatorId,
      assignedTo: _selectedMemberId!,
      specialInstruction: _instructionController.text,
      attachment: _selectedFile,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (res['success'] == true || res['status'] == 'success') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tugas berhasil dikirim')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Gagal membuat tugas')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    _buildFormCard(),
                    const SizedBox(height: 20),
                    _buildInfoBox(),
                    const SizedBox(height: 32),
                    _buildSubmitButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: Colors.black.withValues(alpha: 0.1),
              elevation: 2,
            ),
          ),
          Text(
            'Tugas Baru',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(width: 48), // balancing spacer
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('JUDUL TUGAS'),
          _buildTextField(_titleController, 'Contoh: Laporan Kuartal 3'),
          const SizedBox(height: 24),
          _buildFieldLabel('DESKRIPSI TUGAS'),
          _buildTextField(
            _descriptionController,
            'Jelaskan rincian tugas dan ekspektasi...',
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          _buildFieldLabel('INSTRUKSI KHUSUS (OPSIONAL)'),
          _buildTextField(
            _instructionController,
            'Contoh: Backup data sebelum migrasi...',
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          _buildFieldLabel('PRIORITAS TUGAS'),
          _buildPriorityPicker(),
          const SizedBox(height: 24),
          _buildFieldLabel('TENGGAT WAKTU'),
          _buildDatePickerField(),
          const SizedBox(height: 24),
          _buildFieldLabel('PILIH PENERIMA'),
          _buildMemberPickerField(),
          const SizedBox(height: 24),
          _buildFieldLabel('LAMPIRAN (OPSIONAL)'),
          _buildUploadArea(),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    return InkWell(
      onTap: _pickFile,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _selectedFile != null
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    _selectedFile != null
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                        : const Color(0xFFE2E8F0).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _selectedFile == null
                    ? Icons.attach_file_rounded
                    : Icons.check_circle_rounded,
                size: 20,
                color:
                    _selectedFile != null
                        ? const Color(0xFF3B82F6)
                        : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFile == null ? 'Pilih Berkas' : 'Berkas Terpilih',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    _selectedFile == null
                        ? 'PDF, ZIP, JPG, PNG'
                        : _selectedFile!.path.split('/').last,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (_selectedFile != null)
              IconButton(
                onPressed: () => setState(() => _selectedFile = null),
                icon: const Icon(
                  Icons.cancel_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPriority,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF94A3B8),
          ),
          items:
              _priorities.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                );
              }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedPriority = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDatePickerField() {
    String dateText =
        _selectedDate == null
            ? 'dd/mm/yyyy'
            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';

    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color:
                  _selectedDate == null
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF3B82F6),
            ),
            const SizedBox(width: 12),
            Text(
              dateText,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color:
                    _selectedDate == null
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.date_range_rounded,
              size: 18,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberPickerField() {
    if (_isLoadingSubordinates) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(
              'Memuat data bawahan...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    if (_subordinates.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 20, color: Color(0xFF94A3B8)),
            const SizedBox(width: 12),
            Text(
              'Tidak ada bawahan ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    // Get selected member name
    String? selectedName;
    String? selectedPosition;
    if (_selectedMemberId != null) {
      final selected = _subordinates.firstWhere(
        (s) => int.parse(s['id'].toString()) == _selectedMemberId,
        orElse: () => {},
      );
      if (selected.isNotEmpty) {
        selectedName = selected['full_name'] ?? selected['name'] ?? 'Unknown';
        selectedPosition = selected['position_name'];
      }
    }

    return InkWell(
      onTap: () => _showMemberSearchSheet(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                _selectedMemberId != null
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                    : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedMemberId != null
                  ? Icons.person_rounded
                  : Icons.person_search_rounded,
              size: 20,
              color:
                  _selectedMemberId != null
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child:
                  _selectedMemberId != null
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedName ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (selectedPosition != null)
                            Text(
                              selectedPosition,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      )
                      : Text(
                        'Pilih Penerima Tugas',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showMemberSearchSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _MemberSearchSheet(
          subordinates: _subordinates,
          selectedId: _selectedMemberId,
          onSelected: (id) {
            setState(() {
              _selectedMemberId = id;
            });
          },
        );
      },
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pastikan semua data sudah benar sebelum dikirim.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _submitTask,
        icon:
            _isLoading
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.send_rounded, size: 18),
        label: Text(_isLoading ? 'Mengirim...' : 'Kirim Tugas'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF3B82F6).withValues(alpha: 0.4),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _MemberSearchSheet extends StatefulWidget {
  final List<Map<String, dynamic>> subordinates;
  final int? selectedId;
  final ValueChanged<int> onSelected;

  const _MemberSearchSheet({
    required this.subordinates,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<_MemberSearchSheet> createState() => _MemberSearchSheetState();
}

class _MemberSearchSheetState extends State<_MemberSearchSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredList = [];

  @override
  void initState() {
    super.initState();
    _filteredList = widget.subordinates;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterList(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = widget.subordinates;
      } else {
        _filteredList =
            widget.subordinates.where((sub) {
              final name =
                  (sub['full_name'] ?? sub['name'] ?? '')
                      .toString()
                      .toLowerCase();
              final position =
                  (sub['position_name'] ?? '').toString().toLowerCase();
              return name.contains(query.toLowerCase()) ||
                  position.contains(query.toLowerCase());
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.people_rounded,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Pilih Penerima Tugas',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterList,
                style: GoogleFonts.poppins(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau jabatan...',
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _filterList('');
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF94A3B8),
                              size: 18,
                            ),
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filteredList.length} pegawai ditemukan',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child:
                _filteredList.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Tidak ditemukan',
                            style: GoogleFonts.poppins(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      itemCount: _filteredList.length,
                      separatorBuilder:
                          (_, __) => const Divider(height: 1, indent: 68),
                      itemBuilder: (context, index) {
                        final sub = _filteredList[index];
                        final int id = int.parse(sub['id'].toString());
                        final String name =
                            sub['full_name'] ?? sub['name'] ?? 'Unknown';
                        final String? position = sub['position_name'];
                        final bool isSelected = id == widget.selectedId;
                        final String initial =
                            name.isNotEmpty ? name[0].toUpperCase() : '?';

                        return ListTile(
                          onTap: () {
                            widget.onSelected(id);
                            Navigator.pop(context);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFEFF6FF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                isSelected
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFFE2E8F0),
                            child: Text(
                              initial,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          subtitle:
                              position != null
                                  ? Text(
                                    position,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  )
                                  : null,
                          trailing:
                              isSelected
                                  ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF3B82F6),
                                    size: 24,
                                  )
                                  : null,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
