import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/violation_model.dart';
import '../../services/violation_service.dart';

class OfficerManagementScreen extends StatefulWidget {
  const OfficerManagementScreen({super.key});

  @override
  State<OfficerManagementScreen> createState() => _OfficerManagementScreenState();
}

class _OfficerManagementScreenState extends State<OfficerManagementScreen> {
  List<ViolationOfficer> _officers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOfficers();
  }

  Future<void> _fetchOfficers() async {
    setState(() => _isLoading = true);
    final list = await ViolationService.getOfficers();
    if (mounted) {
      setState(() {
        _officers = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF1F2),
      appBar: AppBar(
        title: Text('Data Petugas Pelanggaran', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _officers.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _officers.length,
                  itemBuilder: (context, index) {
                    final officer = _officers[index];
                    return _buildOfficerCard(officer);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOfficerModal,
        backgroundColor: const Color(0xFFE11D48),
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Tambah Petugas', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield_outlined, size: 80, color: Colors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('Belum ada petugas ditunjuk', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildOfficerCard(ViolationOfficer officer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.1),
            child: Text(officer.nama[0].toUpperCase(), style: const TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(officer.nama, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(officer.position, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _handleDelete(officer),
          ),
        ],
      ),
    );
  }

  void _showAddOfficerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddOfficerSheet(),
    ).then((value) {
      if (value == true) _fetchOfficers();
    });
  }

  void _handleDelete(ViolationOfficer officer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Petugas'),
        content: Text('Apakah Anda yakin ingin menghapus wewenang ${officer.nama}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ViolationService.deleteOfficer(officer.id);
      if (success && mounted) {
        _fetchOfficers();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wewenang petugas berhasil dihapus')));
      }
    }
  }
}

class _AddOfficerSheet extends StatefulWidget {
  const _AddOfficerSheet();

  @override
  State<_AddOfficerSheet> createState() => _AddOfficerSheetState();
}

class _AddOfficerSheetState extends State<_AddOfficerSheet> {
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _filteredEmployees = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final list = await ViolationService.getOfficerEmployees();
    if (mounted) {
      setState(() {
        _employees = list;
        _filteredEmployees = list;
        _isLoading = false;
      });
    }
  }

  void _filter(String q) {
    setState(() {
      _filteredEmployees = _employees
          .where((e) => e['nama'].toString().toLowerCase().contains(q.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Text('Tambah Petugas', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Cari karyawan...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEmployees.isEmpty
                    ? const Center(child: Text('Karyawan tidak ditemukan'))
                    : ListView.separated(
                        itemCount: _filteredEmployees.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final e = _filteredEmployees[index];
                          return ListTile(
                            title: Text(e['nama'] ?? '-', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(e['position_name'] ?? '-', style: GoogleFonts.poppins(fontSize: 12)),
                            trailing: const Icon(Icons.add_circle_outline, color: Color(0xFFE11D48)),
                            onTap: () => _addOfficer(e),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _addOfficer(Map<String, dynamic> employee) async {
    final employeeId = int.tryParse(employee['id'].toString()) ?? 0;
    final success = await ViolationService.addOfficer(employeeId);
    if (success) {
      if (mounted) Navigator.pop(context, true);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menambah petugas atau petugas sudah ada')));
      }
    }
  }
}
