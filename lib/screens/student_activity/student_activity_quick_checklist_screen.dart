import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/student_activity_provider.dart';

class StudentActivityQuickChecklistScreen extends StatefulWidget {
  const StudentActivityQuickChecklistScreen({super.key});

  @override
  State<StudentActivityQuickChecklistScreen> createState() =>
      _StudentActivityQuickChecklistScreenState();
}

class _StudentActivityQuickChecklistScreenState
    extends State<StudentActivityQuickChecklistScreen> {
  final _formKey = GlobalKey<FormState>();

  int? _selectedActivityTypeId;
  DateTime _selectedDate = DateTime.now();
  final Set<int> _checkedStudentIds = {};
  String _searchQuery = '';
  String? _selectedClass;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<StudentActivityProvider>(
        context,
        listen: false,
      );
      provider.fetchActivityTypes();
      provider.fetchStudents();
    });
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

  void _toggleStudent(int studentId) {
    setState(() {
      if (_checkedStudentIds.contains(studentId)) {
        _checkedStudentIds.remove(studentId);
      } else {
        _checkedStudentIds.add(studentId);
      }
    });
  }

  void _toggleSelectAll(List<Map<String, dynamic>> students) {
    setState(() {
      if (_checkedStudentIds.length == students.length) {
        _checkedStudentIds.clear();
      } else {
        for (var student in students) {
          final id = int.tryParse(student['id'].toString());
          if (id != null) {
            _checkedStudentIds.add(id);
          }
        }
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedActivityTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jenis Aktivitas wajib dipilih.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_checkedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih minimal satu siswa yang melaksanakan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final provider = Provider.of<StudentActivityProvider>(
      context,
      listen: false,
    );
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final success = await provider.createBatchActivity(
      activityTypeId: _selectedActivityTypeId!,
      activityDate: dateStr,
      status: 'completed', // Default completed for checklist
      studentIds: _checkedStudentIds.toList(),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aktivitas siswa berhasil dicatat.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            provider.errorMessage ?? 'Gagal mencatat batch aktivitas.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<StudentActivityProvider>(context);

    // Extract unique classes dynamically
    final classes =
        provider.students
            .map((s) => s['kelas']?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList();
    classes.sort();

    // Filter students by query & class
    final filteredStudents =
        provider.students.where((s) {
          final name = s['full_name']?.toString().toLowerCase() ?? '';
          final kelas = s['kelas']?.toString() ?? '';
          final query = _searchQuery.toLowerCase();

          final matchesSearch = name.contains(query);
          final matchesClass =
              _selectedClass == null ||
              kelas.toLowerCase() == _selectedClass!.toLowerCase();

          return matchesSearch && matchesClass;
        }).toList();

    final allSelected =
        filteredStudents.isNotEmpty &&
        filteredStudents.every(
          (s) => _checkedStudentIds.contains(int.tryParse(s['id'].toString())),
        );

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
          'Input Cepat (Checklist)',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body:
          provider.isLoading && provider.students.isEmpty
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF009688)),
              )
              : Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Form config panel
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Jenis Aktivitas Dropdown
                          Text(
                            'Jenis Aktivitas',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonFormField<int>(
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                              value: _selectedActivityTypeId,
                              hint: Text(
                                'Pilih jenis aktivitas',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                              items:
                                  provider.activityTypes.map((type) {
                                    return DropdownMenuItem<int>(
                                      value: type.id,
                                      child: Text(
                                        type.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedActivityTypeId = val;
                                });
                              },
                              validator:
                                  (value) =>
                                      value == null
                                          ? 'Jenis aktivitas wajib dipilih'
                                          : null,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Date Selector
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tanggal',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _selectDate,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              DateFormat(
                                                'dd MMMM yyyy',
                                                'id_ID',
                                              ).format(_selectedDate),
                                              style: GoogleFonts.poppins(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1E293B),
                                              ),
                                            ),
                                            const Icon(
                                              Icons.calendar_today_outlined,
                                              color: Color(0xFF64748B),
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Search Bar and Checklist Options
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      color: const Color(0xFFF8FAFC),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: TextField(
                                    style: GoogleFonts.poppins(fontSize: 12),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(
                                        Icons.search,
                                        color: Color(0xFF94A3B8),
                                        size: 18,
                                      ),
                                      hintText: 'Cari nama siswa...',
                                      hintStyle: GoogleFonts.poppins(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 12,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _searchQuery = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 42,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedClass,
                                    hint: Text(
                                      'Kelas',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 18,
                                      color: Color(0xFF64748B),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text(
                                          'Semua Kelas',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      ...classes.map(
                                        (c) => DropdownMenuItem<String>(
                                          value: c,
                                          child: Text(
                                            c,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedClass = val;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daftar Siswa (${_checkedStudentIds.length}/${filteredStudents.length} Terpilih)',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              TextButton.icon(
                                onPressed:
                                    () => _toggleSelectAll(filteredStudents),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(50, 30),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(
                                  allSelected
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  size: 16,
                                  color: const Color(0xFF009688),
                                ),
                                label: Text(
                                  allSelected ? 'Hapus Semua' : 'Pilih Semua',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF009688),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Student Checklist List
                    Expanded(
                      child:
                          filteredStudents.isEmpty
                              ? Center(
                                child: Text(
                                  'Siswa tidak ditemukan.',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF94A3B8),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                              : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = filteredStudents[index];
                                  final id =
                                      int.tryParse(student['id'].toString()) ??
                                      0;
                                  final isChecked = _checkedStudentIds.contains(
                                    id,
                                  );

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            isChecked
                                                ? const Color(
                                                  0xFF009688,
                                                ).withValues(alpha: 0.3)
                                                : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: CheckboxListTile(
                                      activeColor: const Color(0xFF009688),
                                      checkboxShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      value: isChecked,
                                      onChanged: (val) => _toggleStudent(id),
                                      title: Text(
                                        student['full_name'] ?? '',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color:
                                              isChecked
                                                  ? const Color(0xFF009688)
                                                  : const Color(0xFF334155),
                                        ),
                                      ),
                                      subtitle: Text(
                                        "Kelas ${student['kelas'] ?? ''} • ${student['tingkat'] ?? ''}",
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),

                    // Bottom panel with save button
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
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
                          child:
                              provider.isSaving
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  )
                                  : Text(
                                    "Simpan (${_checkedStudentIds.length} Siswa)",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
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
