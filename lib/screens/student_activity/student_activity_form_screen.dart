import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/student_activity_model.dart';
import '../../providers/student_activity_provider.dart';

class StudentActivityFormScreen extends StatefulWidget {
  final StudentActivity? activity;

  const StudentActivityFormScreen({super.key, this.activity});

  @override
  State<StudentActivityFormScreen> createState() => _StudentActivityFormScreenState();
}

class _StudentActivityFormScreenState extends State<StudentActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  bool get _isEditMode => widget.activity != null;

  int? _selectedActivityTypeId;
  int? _selectedStudentId;
  String? _selectedStudentName;
  String? _selectedStudentClass;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _selectedStatus = 'completed';
  final TextEditingController _noteController = TextEditingController();

  // Attachments state
  final List<File> _newFiles = [];
  final List<ActivityAttachment> _existingAttachments = [];
  final List<int> _attachmentsToDelete = [];

  @override
  void initState() {
    super.initState();
    
    // Initial fetch for dropdown lists if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudentActivityProvider>(context, listen: false);
      provider.fetchActivityTypes();
      provider.fetchStudents();
    });

    if (_isEditMode) {
      final act = widget.activity!;
      _selectedActivityTypeId = act.activityTypeId;
      _selectedStudentId = act.studentId;
      _selectedStudentName = act.studentName;
      _selectedStudentClass = act.studentClass;
      _selectedDate = DateTime.parse(act.activityDate);
      
      if (act.startTime != null) {
        final parts = act.startTime!.split(':');
        _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      if (act.endTime != null) {
        final parts = act.endTime!.split(':');
        _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
      
      _selectedStatus = act.status;
      _noteController.text = act.note ?? '';
      _existingAttachments.addAll(act.attachments);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _newFiles.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _removeNewFile(int index) {
    setState(() {
      _newFiles.removeAt(index);
    });
  }

  void _removeExistingAttachment(int index) {
    final attachment = _existingAttachments[index];
    setState(() {
      _attachmentsToDelete.add(attachment.id);
      _existingAttachments.removeAt(index);
    });
  }

  void _showStudentSearchBottomSheet() {
    String filterText = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Consumer<StudentActivityProvider>(
          builder: (context, studentProvider, child) {
            return StatefulBuilder(
              builder: (context, setModalState) {
                final filteredList = studentProvider.students.where((s) {
                  final name = s['full_name']?.toString().toLowerCase() ?? '';
                  final kelas = s['kelas']?.toString().toLowerCase() ?? '';
                  final query = filterText.toLowerCase();
                  return name.contains(query) || kelas.contains(query);
                }).toList();

                return Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Pilih Siswa',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          style: GoogleFonts.poppins(fontSize: 13),
                          decoration: InputDecoration(
                            icon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                            hintText: 'Cari nama siswa atau kelas...',
                            hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              filterText = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: studentProvider.isLoading
                            ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
                            : filteredList.isEmpty
                                ? Center(
                                    child: Text(
                                      'Siswa tidak ditemukan.',
                                      style: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 13),
                                    ),
                                  )
                                : ListView.separated(
                                    itemCount: filteredList.length,
                                    separatorBuilder: (context, index) => const Divider(),
                                    itemBuilder: (context, index) {
                                      final student = filteredList[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor: const Color(0xFFE0F2F1),
                                          child: Text(
                                            student['full_name']?[0]?.toUpperCase() ?? 'S',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF009688),
                                            ),
                                          ),
                                        ),
                                        title: Text(
                                          student['full_name'] ?? '',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: const Color(0xFF334155),
                                          ),
                                        ),
                                        subtitle: Text(
                                          "Kelas ${student['kelas'] ?? ''} • ${student['tingkat'] ?? ''}",
                                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B)),
                                        ),
                                        onTap: () {
                                          setState(() {
                                            _selectedStudentId = int.tryParse(student['id'].toString());
                                            _selectedStudentName = student['full_name'];
                                            _selectedStudentClass = student['kelas'];
                                          });
                                          Navigator.pop(context);
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pilih Sumber Foto',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0F2F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF009688), size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kamera',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE0F2F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.photo_library_rounded, color: Color(0xFF009688), size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Galeri',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF009688),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF009688),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeOfDay(TimeOfDay? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm:ss').format(dt);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Siswa wajib dipilih.'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedActivityTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jenis Aktivitas wajib dipilih.'), backgroundColor: Colors.red),
      );
      return;
    }

    final provider = Provider.of<StudentActivityProvider>(context, listen: false);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final startTimeStr = _startTime != null ? _formatTimeOfDay(_startTime) : null;
    final endTimeStr = _endTime != null ? _formatTimeOfDay(_endTime) : null;

    bool success = false;

    if (_isEditMode) {
      success = await provider.updateActivity(
        id: widget.activity!.id,
        activityTypeId: _selectedActivityTypeId,
        studentId: _selectedStudentId,
        activityDate: dateStr,
        status: _selectedStatus,
        startTime: startTimeStr,
        endTime: endTimeStr,
        note: _noteController.text,
        attachmentsToAdd: _newFiles,
        attachmentsToDelete: _attachmentsToDelete,
      );
    } else {
      success = await provider.createActivity(
        activityTypeId: _selectedActivityTypeId!,
        studentId: _selectedStudentId!,
        activityDate: dateStr,
        status: _selectedStatus,
        startTime: startTimeStr,
        endTime: endTimeStr,
        note: _noteController.text,
        attachments: _newFiles,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode ? 'Aktivitas berhasil diperbarui.' : 'Aktivitas berhasil dicatat.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // If edit mode, pass back the updated StudentActivity from the provider list
      if (_isEditMode) {
        final updatedActivity = provider.activities.firstWhere((a) => a.id == widget.activity!.id, orElse: () => widget.activity!);
        Navigator.pop(context, updatedActivity);
      } else {
        Navigator.pop(context);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan data.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentActivityProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEditMode ? 'Edit Aktivitas' : 'Tambah Aktivitas',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: provider.isLoading && provider.activityTypes.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF009688)))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Jenis Aktivitas Dropdown
                  Text(
                    'Jenis Aktivitas',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonFormField<int>(
                      decoration: const InputDecoration(border: InputBorder.none),
                      value: _selectedActivityTypeId,
                      hint: Text('Pilih jenis aktivitas', style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF94A3B8))),
                      items: provider.activityTypes.map((type) {
                        return DropdownMenuItem<int>(
                          value: type.id,
                          child: Text(type.name, style: GoogleFonts.poppins(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedActivityTypeId = val;
                        });
                      },
                      validator: (value) => value == null ? 'Jenis aktivitas wajib dipilih' : null,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Student Selector (Searchable Bottom Sheet)
                  Text(
                    'Pilih Siswa',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _isEditMode ? null : _showStudentSearchBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: _isEditMode ? const Color(0xFFF1F5F9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedStudentName == null
                                  ? 'Pilih nama siswa...'
                                  : "$_selectedStudentName ($_selectedStudentClass)",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: _selectedStudentName == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                fontWeight: _selectedStudentName != null ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (!_isEditMode)
                            const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Picker
                  Text(
                    'Tanggal',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(_selectedDate),
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
                          ),
                          const Icon(Icons.calendar_today_outlined, color: Color(0xFF64748B), size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Time Pickers
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Jam Mulai',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectTime(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _startTime?.format(context) ?? 'Mulai',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: _startTime == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                        fontWeight: _startTime != null ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    const Icon(Icons.access_time, color: Color(0xFF64748B), size: 18),
                                  ],
                                ),
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
                            Text(
                              'Jam Selesai',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _selectTime(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _endTime?.format(context) ?? 'Selesai',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: _endTime == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                                        fontWeight: _endTime != null ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    const Icon(Icons.access_time, color: Color(0xFF64748B), size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Status Dropdown
                  Text(
                    'Status',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(border: InputBorder.none),
                      value: _selectedStatus,
                      items: [
                        DropdownMenuItem<String>(
                          value: 'completed',
                          child: Text('Dilaksanakan', style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'not_completed',
                          child: Text('Tidak Dilaksanakan', style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                        DropdownMenuItem<String>(
                          value: 'excused',
                          child: Text('Berhalangan', style: GoogleFonts.poppins(fontSize: 13)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedStatus = val;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notes Text Field
                  Text(
                    'Catatan (Opsional)',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextFormField(
                      controller: _noteController,
                      maxLines: 4,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Tambahkan catatan aktivitas...',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Documentation Selection
                  Text(
                    'Dokumentasi',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                  ),
                  const SizedBox(height: 12),

                  // Image Previews Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _existingAttachments.length + _newFiles.length + 1,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      // 1. Existing Attachments
                      if (index < _existingAttachments.length) {
                        final attachment = _existingAttachments[index];
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  attachment.url,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeExistingAttachment(index),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // 2. New Picked Files
                      final newFileIndex = index - _existingAttachments.length;
                      if (newFileIndex < _newFiles.length) {
                        final file = _newFiles[newFileIndex];
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  file,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => _removeNewFile(newFileIndex),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // 3. Add Photo Button
                      return GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
                          ),
                          child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF64748B), size: 22),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009688),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: provider.isSaving ? null : _save,
                      child: provider.isSaving
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : Text(
                              _isEditMode ? 'Simpan Perubahan' : 'Catat Aktivitas',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
