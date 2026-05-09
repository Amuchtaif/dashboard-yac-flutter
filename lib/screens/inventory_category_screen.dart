import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dashboard_yac/screens/inventory_list_screen.dart';
import '../models/inventory_location_model.dart';
import '../services/inventory_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryCategoryScreen extends StatefulWidget {
  final List<InventoryLocationModel>? locations;
  final String title;

  const InventoryCategoryScreen({super.key, this.locations, String? title})
    : title = title ?? 'Lokasi Inventaris';

  @override
  State<InventoryCategoryScreen> createState() =>
      _InventoryCategoryScreenState();
}

class _InventoryCategoryScreenState extends State<InventoryCategoryScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<InventoryLocationModel> _locations = [];
  bool _isLoading = false;
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
      bool isUmumOrSarpras =
          _userDivision.toLowerCase().contains('umum') ||
          _userDivision.toLowerCase().contains('sarpras') ||
          _userPositionName.toLowerCase().contains('umum') ||
          _userPositionName.toLowerCase().contains('sarpras');

      _isSuperAdmin = isLevel1 || isUmumOrSarpras;

      debugPrint(
        "🔍 Inventory Filter - Div: $_userDivision, Unit: $_userUnit, Level: $_userPositionLevel, Admin: $_isSuperAdmin",
      );
    });

    if (widget.locations != null) {
      // Filter passed sub-locations as well
      if (!_isSuperAdmin && _userDivision.isNotEmpty) {
        _locations =
            widget.locations!
                .where((loc) => _locationMatchesDivision(loc))
                .toList();
      } else {
        _locations = widget.locations!;
      }
    } else {
      _fetchRootLocations();
    }
  }

  Future<void> _fetchRootLocations() async {
    setState(() => _isLoading = true);
    try {
      final allLocations = await _inventoryService.getLocations();
      if (mounted) {
        setState(() {
          List<InventoryLocationModel> filtered = allLocations;

          // Apply recursive division filter if not admin
          if (!_isSuperAdmin && _userDivision.isNotEmpty) {
            filtered =
                allLocations
                    .where((loc) => _locationMatchesDivision(loc))
                    .toList();
          }

          _locations = filtered;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil data: $e')));
      }
    }
  }

  List<InventoryLocationModel> get _filteredLocations {
    if (_searchQuery.isEmpty) return _locations;
    return _locations.where((loc) {
      return loc.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  bool _locationMatchesDivision(InventoryLocationModel loc) {
    if (_isSuperAdmin) return true;

    final locationName = loc.name.toLowerCase().trim();
    final division = _userDivision.toLowerCase().trim();
    final unit = _userUnit.toLowerCase().trim();

    bool selfMatches = false;
    final effectiveDivision = _getEffectiveDivision(division);

    // Check for Unit match
    if (unit.isNotEmpty) {
      if (locationName == unit ||
          locationName.startsWith('$unit ') ||
          locationName.endsWith(' $unit') ||
          locationName.contains(' $unit ')) {
        selfMatches = true;
      }
    }

    // Check for Division match as fallback
    // IF no unit match AND (no unit assigned OR unit is a general/non-school unit)
    if (!selfMatches && effectiveDivision.isNotEmpty) {
      final u = unit.toLowerCase();
      bool isSchoolUnit =
          u == 'ma' ||
          u == 'mts' ||
          u == 'tkit' ||
          u == 'sdit' ||
          u == 'mi' ||
          u == 'tahfidz' ||
          u.contains('ma\'had aly') ||
          u.contains('mahad aly');

      bool isGeneralUnit =
          unit.isEmpty ||
          !isSchoolUnit ||
          u.contains('yayasan') ||
          u.contains('pusat') ||
          u.contains('sekretariat') ||
          u.contains('kantor') ||
          u.contains('pendidikan') ||
          u.contains('kesantrian');

      if (isGeneralUnit) {
        if (locationName == effectiveDivision ||
            locationName.contains(effectiveDivision)) {
          selfMatches = true;
        }
        if (!selfMatches &&
            division.isNotEmpty &&
            locationName.contains(division)) {
          selfMatches = true;
        }
      }
    }

    if (selfMatches) return true;

    // Check if any child matches (recursive)
    for (var child in loc.children) {
      if (_locationMatchesDivision(child)) return true;
    }

    return false;
  }

  String _getEffectiveDivision(String div) {
    final d = div.toLowerCase();
    // Map sub-divisions to parent divisions
    if (d.contains('kurikulum') ||
        d.contains('akademik') ||
        d.contains('pengajaran') ||
        d.contains('guru')) {
      return 'pendidikan';
    }
    if (d.contains('pengasuhan') ||
        d.contains('asrama') ||
        d.contains('kesantrian')) {
      return 'kesantrian';
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildSearchBar(),
            const SizedBox(height: 10),
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredLocations.isEmpty
                      ? _buildEmptyState()
                      : _buildCategoryGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: TextField(
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Cari lokasi...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.blue.shade400),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredLocations.length,
      itemBuilder: (context, index) {
        final location = _filteredLocations[index];
        return _buildCategoryCard(location);
      },
    );
  }

  Widget _buildCategoryCard(InventoryLocationModel location) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey.shade50),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (location.children.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => InventoryCategoryScreen(
                        locations: location.children,
                        title: location.name,
                      ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => InventoryListScreen(
                        categoryTitle: location.name,
                        locationId: location.id,
                      ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    location.children.isNotEmpty
                        ? Icons.folder_rounded
                        : Icons.inventory_2_rounded,
                    color: const Color(0xFF0085FF),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  location.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    location.children.isNotEmpty
                        ? '${location.children.length} SUB'
                        : 'LIHAT ITEM',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0085FF),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Lokasi tidak ditemukan',
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
