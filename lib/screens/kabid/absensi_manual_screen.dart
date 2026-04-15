import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/kabid_service.dart';

class AbsensiManualScreen extends StatefulWidget {
  const AbsensiManualScreen({super.key});

  @override
  State<AbsensiManualScreen> createState() => _AbsensiManualScreenState();
}

class _AbsensiManualScreenState extends State<AbsensiManualScreen> {
  final KabidService _kabidService = KabidService();
  final TextEditingController _noteController = TextEditingController();

  List<Map<String, dynamic>> _staffList = [];
  String? _selectedStaffId;
  String _selectedType = 'Masuk';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoadingStaff = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    if (!mounted) return;
    setState(() => _isLoadingStaff = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;
      final results = await _kabidService.getStaffList(userId);
      if (!mounted) return;
      setState(() {
        _staffList = results;
        _isLoadingStaff = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingStaff = false);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submit() async {
    if (_selectedStaffId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih karyawan terlebih dahulu')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final kabidId = prefs.getInt('user_id') ?? prefs.getInt('userId') ?? 0;

      final data = {
        'kabid_id': kabidId,
        'staff_id': int.parse(_selectedStaffId!),
        'type': _selectedType.toUpperCase(),
        'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'time':
            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
        'note': _noteController.text,
      };

      final result = await _kabidService.saveManualAttendance(data);

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Berhasil simpan presensi'),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        if (result['success']) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
        );
      }
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIllustration(),
                    const SizedBox(height: 32),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildSubmitButton(),
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
            'Absensi Manual',
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

  Widget _buildIllustration() {
    return Center(
      child: Container(
        height: 160,
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF0D9488).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.edit_calendar_rounded,
          size: 80,
          color: Color(0xFF0D9488),
        ),
      ),
    );
  }

  Widget _buildForm() {
    // Find the currently selected staff name
    final selectedStaffName =
        _staffList.firstWhere(
          (s) => s['id'].toString() == _selectedStaffId,
          orElse: () => {'name': 'Cari nama karyawan...'},
        )['name'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Pilih Karyawan'),
        const SizedBox(height: 8),
        _buildPickerTile(
          icon: Icons.person_search_rounded,
          value: _isLoadingStaff ? 'Memuat karyawan...' : selectedStaffName,
          onTap: _isLoadingStaff ? () {} : _showStaffSearch,
        ),
        const SizedBox(height: 20),
        _buildLabel('Jenis Presensi'),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildTypeOption('Masuk'),
            const SizedBox(width: 12),
            _buildTypeOption('Pulang'),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Tanggal'),
                  const SizedBox(height: 8),
                  _buildPickerTile(
                    icon: Icons.calendar_today_rounded,
                    value: DateFormat('dd/MM/yyyy').format(_selectedDate),
                    onTap: _pickDate,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Waktu'),
                  const SizedBox(height: 8),
                  _buildPickerTile(
                    icon: Icons.access_time_rounded,
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _buildLabel('Alasan Manual'),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          maxLines: 3,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Contoh: Lupa scan, Kendala perangkat...',
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  void _showStaffSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final List<Map<String, dynamic>> filteredList =
                _staffList
                    .where(
                      (s) => s['name'].toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                    )
                    .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setModalState(() => _searchQuery = v),
                      style: GoogleFonts.poppins(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Cari nama staf...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final staff = filteredList[index];
                        return ListTile(
                          title: Text(
                            staff['name'],
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedStaffId = staff['id'].toString();
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
  }

  String _searchQuery = '';

  Widget _buildTypeOption(String type) {
    bool isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0D9488) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? const Color(0xFF0D9488)
                      : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Text(
              type,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton(
        onPressed: (_isSaving || _isLoadingStaff) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0D9488),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.3),
        ),
        child:
            _isSaving
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  'Simpan Presensi',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF64748B),
      ),
    );
  }
}
