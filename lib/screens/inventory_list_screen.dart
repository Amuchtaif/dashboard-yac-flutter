import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_service.dart';
import 'inventory_form_screen.dart';

class InventoryListScreen extends StatefulWidget {
  final String categoryTitle;
  final int? locationId;

  const InventoryListScreen({
    super.key,
    String? categoryTitle,
    this.locationId,
  }) : categoryTitle = categoryTitle ?? 'Inventaris';

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<InventoryItemModel> _allItems = [];
  List<InventoryItemModel> _filteredItems = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // Filtering based on user division
  String _userDivision = '';
  String _userUnit = '';
  int _userPositionLevel = 99;
  String _userPositionName = '';
  bool _isSuperAdmin = false;
  
  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  Future<void> _loadUserAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userDivision = prefs.getString('divisionName') ?? '';
      _userUnit = prefs.getString('unitName') ?? '';
      _userPositionLevel = prefs.getInt('positionLevel') ?? 99;
      _userPositionName = prefs.getString('positionName') ?? '';
      
      // Full access for Level 1 (Mudir) or anyone in "Umum"/"Sarpras"
      bool isLevel1 = _userPositionLevel == 1;
      bool isUmumOrSarpras = _userDivision.toLowerCase().contains('umum') || 
                             _userDivision.toLowerCase().contains('sarpras') ||
                             _userPositionName.toLowerCase().contains('umum') ||
                             _userPositionName.toLowerCase().contains('sarpras');

      _isSuperAdmin = isLevel1 || isUmumOrSarpras;
    });
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _inventoryService.getItems(locationId: widget.locationId);
      if (mounted) {
        setState(() {
          _allItems = _applyDivisionFilter(items);
          _filterItems();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: $e')),
        );
      }
    }
  }

  List<InventoryItemModel> _applyDivisionFilter(List<InventoryItemModel> items) {
    if (_isSuperAdmin) return items;
    
    final division = _userDivision.toLowerCase().trim();
    final unit = _userUnit.toLowerCase().trim();

    return items.where((item) {
      final breadcrumb = (item.locationBreadcrumb ?? '').toLowerCase();
      if (breadcrumb.isEmpty) return false;

      final segments = breadcrumb.split(' > ').map((s) => s.trim()).toList();
      
      // Helper for strict word matching
      bool matchesWord(String target, String source) {
        if (target.isEmpty) return false;
        return source == target || 
               source.startsWith('$target ') || 
               source.endsWith(' $target') || 
               source.contains(' $target ');
      }

      // Check if any segment matches unit or division
      bool unitMatches = unit.isNotEmpty && segments.any((s) => matchesWord(unit, s));
      
      final effectiveDivision = _getEffectiveDivision(division);
      bool divisionMatches = division.isNotEmpty && (
          segments.any((s) => matchesWord(division, s)) || 
          segments.any((s) => matchesWord(effectiveDivision, s))
      );
      
      // If user has a unit, check if it's a school unit or general unit
      if (unit.isNotEmpty) {
        final u = unit.toLowerCase();
        bool isSchoolUnit = u == 'ma' || u == 'mts' || u == 'tkit' || 
                            u == 'sdit' || u == 'mi' || u == 'tahfidz' || 
                            u.contains('ma\'had aly') || u.contains('mahad aly');
        
        bool isGeneralUnit = !isSchoolUnit || 
                             u.contains('yayasan') || u.contains('pusat') || 
                             u.contains('sekretariat') || u.contains('kantor') ||
                             u.contains('pendidikan') || u.contains('kesantrian');
                             
        if (isGeneralUnit) {
          // General unit: can see both their unit AND their whole division
          return unitMatches || divisionMatches;
        } else {
          // School unit: strictly restricted to their unit
          return unitMatches;
        }
      }
      
      // If no unit, match by division
      return divisionMatches;
    }).toList();
  }

  String _getEffectiveDivision(String div) {
    final d = div.toLowerCase();
    // Map sub-divisions to parent divisions
    if (d.contains('kurikulum') || d.contains('akademik') || d.contains('pengajaran') || d.contains('guru')) {
      return 'pendidikan';
    }
    if (d.contains('pengasuhan') || d.contains('asrama') || d.contains('kesantrian')) {
      return 'kesantrian';
    }
    return d;
  }

  void _filterItems() {
    // Search filter based on already division-filtered _allItems
    if (_searchQuery.isEmpty) {
      _filteredItems = _allItems;
    } else {
      _filteredItems = _allItems.where((item) {
        final nameMatch = item.name.toLowerCase().contains(_searchQuery.toLowerCase());
        final codeMatch = item.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        final locationMatch = item.locationBreadcrumb?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
        return nameMatch || codeMatch || locationMatch;
      }).toList();
    }
  }

  int get _totalUniqueItems => _allItems.length;
  int get _totalQuantity => _allItems.fold(0, (sum, item) => sum + item.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryTitle,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          if (!_isLoading && _allItems.isNotEmpty) _buildSummaryCards(),
          _buildSearchAndFilter(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmptyState()
                    : _buildItemList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => InventoryFormScreen(
                locationId: widget.locationId,
              )
            )
          );
          if (result == true) _fetchItems();
        },
        backgroundColor: const Color(0xFF0085FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }


  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              title: 'Total Barang',
              value: '$_totalUniqueItems',
              icon: Icons.inventory_2_rounded,
              color: const Color(0xFF0085FF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryItem(
              title: 'Total Stok',
              value: '$_totalQuantity',
              icon: Icons.pie_chart_rounded,
              color: const Color(0xFFFF9500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _filterItems();
          });
        },
        decoration: InputDecoration(
          hintText: 'Cari barang, kode, atau lokasi...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF1F3F4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildItemList() {
    return RefreshIndicator(
      onRefresh: _fetchItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return _buildItemCard(item);
        },
      ),
    );
  }

  Widget _buildItemCard(InventoryItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final result = await Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => InventoryFormScreen(item: item))
            );
            if (result == true) _fetchItems();
          },
          onLongPress: () => _confirmDelete(item),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey,
                              size: 20,
                            ),
                          ),
                        )
                      : const Icon(Icons.inventory_2, color: Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      if (item.code != null)
                        Text(
                          item.code!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 10, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.locationBreadcrumb ?? 'Lokasi tidak diatur',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (item.purchaseDate != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              'Tgl Beli: ${DateFormat('dd MMM yyyy').format(item.purchaseDate!)}',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (item.condition?.toLowerCase() == 'baik' 
                              ? Colors.green.shade50 
                              : (item.condition?.toLowerCase() == 'rusak ringan' 
                                  ? Colors.orange.shade50 
                                  : Colors.red.shade50)),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: (item.condition?.toLowerCase() == 'baik' 
                                ? Colors.green.shade200 
                                : (item.condition?.toLowerCase() == 'rusak ringan' 
                                    ? Colors.orange.shade200 
                                    : Colors.red.shade200)),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          item.condition ?? 'Baik',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: (item.condition?.toLowerCase() == 'baik' 
                                ? Colors.green.shade700 
                                : (item.condition?.toLowerCase() == 'rusak ringan' 
                                    ? Colors.orange.shade700 
                                    : Colors.red.shade700)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.quantity}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: const Color(0xFF0085FF),
                      ),
                    ),
                    Text(
                      item.unit ?? 'Pcs',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
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

  void _confirmDelete(InventoryItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: Text('Apakah Anda yakin ingin menghapus ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItem(item.id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteItem(int id) async {
    final result = await _inventoryService.deleteItem(id);
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Text('Barang berhasil dihapus', style: GoogleFonts.poppins(fontSize: 13)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.fixed, // Di bawah FAB
          ),
        );
        _fetchItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['message'] ?? 'Gagal menghapus',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.fixed, // Di bawah FAB
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Barang tidak ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

}
