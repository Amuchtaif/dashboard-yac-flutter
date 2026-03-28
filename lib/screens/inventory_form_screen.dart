import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../models/inventory_item_model.dart';
import '../models/inventory_location_model.dart';
import '../services/inventory_service.dart';
import '../widgets/location_tree_picker.dart';

class InventoryFormScreen extends StatefulWidget {
  final InventoryItemModel? item;
  final int? locationId;

  const InventoryFormScreen({super.key, this.item, this.locationId});

  @override
  State<InventoryFormScreen> createState() => _InventoryFormScreenState();
}

class _InventoryFormScreenState extends State<InventoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final InventoryService _inventoryService = InventoryService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _conditionController;

  InventoryLocationModel? _selectedLocation;
  List<InventoryLocationModel> _locations = [];
  File? _imageFile;
  bool _isSaving = false;
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');

    // Auto-generate code if new item
    String initialCode = widget.item?.code ?? '';
    _codeController = TextEditingController(text: initialCode);

    _descriptionController = TextEditingController(
      text: widget.item?.description ?? '',
    );

    // Set default quantity to '1' for new items
    _quantityController = TextEditingController(
      text: widget.item != null ? widget.item!.quantity.toString() : '1',
    );
    _unitController = TextEditingController(
      text:
          (widget.item?.unit == null ||
                  widget.item?.unit == 'null' ||
                  widget.item!.unit!.isEmpty)
              ? 'Pcs'
              : widget.item!.unit,
    );
    _conditionController = TextEditingController(
      text: widget.item?.condition ?? 'Baik',
    );

    // Add listener for auto-generation (only for new items)
    if (widget.item == null) {
      _nameController.addListener(_updateGeneratedCode);
    }

    _fetchLocations();
  }

  String _generateAbbreviation(String text) {
    if (text.isEmpty) return "???";
    // Trim and remove special chars like Ma'had -> Mahad
    String cleanText = text.replaceAll(RegExp(r"[^a-zA-Z0-9\s]"), "");
    List<String> words =
        cleanText.split(' ').where((w) => w.isNotEmpty).toList();

    if (words.length == 1) {
      String word = words[0];
      if (word.length <= 3) return word.toUpperCase();
      // Remove vowels but keep first letter if it's a vowel?
      // User says MTs -> MTS. MTs has vogel 's'. Wait MTs is M-T-S.
      // Usually MTs is M-T-S.
      return word.toUpperCase();
    }

    return words
        .map((word) {
          if (word.length <= 3) return word.toUpperCase();
          // Remove vowels
          String noVowels = word.replaceAll(
            RegExp(r'[aeiouAEIOU]', caseSensitive: false),
            '',
          );
          if (noVowels.isEmpty) return word.substring(0, 1).toUpperCase();
          String result = noVowels.toUpperCase();
          return result.length > 3 ? result.substring(0, 3) : result;
        })
        .join('-');
  }

  void _updateGeneratedCode() async {
    if (widget.item != null) return; // Only for new items
    if (_selectedLocation == null) return;

    final String locAbbr = _generateAbbreviation(_selectedLocation!.name);
    final String itemAbbr = _generateAbbreviation(_nameController.text);

    // Get sequence number per location
    try {
      final items = await _inventoryService.getItems(
        locationId: _selectedLocation!.id,
      );
      // Filter out only items that follow this V2 pattern to count correctly?
      // Or just total items in that location + 1.
      final int nextSeq = items.length + 1;
      final String seqStr = nextSeq.toString().padLeft(3, '0');

      if (mounted) {
        _codeController.text = "$locAbbr-$itemAbbr-$seqStr";
      }
    } catch (e) {
      debugPrint("Error fetching items for code generation: $e");
    }
  }

  Future<void> _fetchLocations() async {
    setState(() => _isLoadingLocations = true);
    final locations = await _inventoryService.getLocations();
    if (mounted) {
      setState(() {
        _locations = locations;
        _isLoadingLocations = false;

        if (widget.item != null) {
          _findSelectedLocation(locations, widget.item!.locationId);
        } else if (widget.locationId != null) {
          _findSelectedLocation(locations, widget.locationId!);
        }

        // If it's a new item and a location is pre-selected or found, update the code
        if (widget.item == null && _selectedLocation != null) {
          _updateGeneratedCode();
        }
      });
    }
  }

  void _findSelectedLocation(List<InventoryLocationModel> locations, int id) {
    for (var loc in locations) {
      if (loc.id == id) {
        _selectedLocation = loc;
        return;
      }
      if (loc.children.isNotEmpty) {
        _findSelectedLocation(loc.children, id);
        if (_selectedLocation != null) return;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pilih Sumber Gambar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildImageSourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: 'Kamera',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _buildImageSourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Galeri',
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.blue, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.poppins(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Silakan pilih lokasi')));
      return;
    }

    setState(() => _isSaving = true);
    final int qtyValue = int.tryParse(_quantityController.text) ?? 0;
    final itemData = {
      if (widget.item != null) 'id': widget.item!.id.toString(),
      'name': _nameController.text,
      'item_code': _codeController.text,
      'location_id': _selectedLocation!.id.toString(),
      'qty': qtyValue.toString(),
      'item_unit': _unitController.text,
      'item_condition': _conditionController.text,
      'description': _descriptionController.text,

      // Backward compatibility aliases
      'nama_barang': _nameController.text,
      'kode_barang': _codeController.text,
      'jumlah_barang': qtyValue.toString(),
      'satuan_barang': _unitController.text,
      'kondisi_barang': _conditionController.text,
      'keterangan': _descriptionController.text,
    };

    final result = await _inventoryService.saveItemMultipart(
      itemData: itemData,
      imageFile: _imageFile,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success'] == true) {
        final String message =
            widget.item != null
                ? 'Data barang berhasil diperbarui'
                : 'Barang berhasil ditambahkan ke inventaris';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.fixed,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result['message'] ?? 'Gagal menyimpan',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
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

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih Lokasi',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: LocationTreePicker(
                    locations: _locations,
                    selectedLocationId: _selectedLocation?.id,
                    onSelected: (loc) {
                      setState(() => _selectedLocation = loc);
                      _updateGeneratedCode();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.item == null ? 'Tambah Item Baru' : 'Perbarui Item',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(
                      'FOTO BARANG',
                      Icons.camera_alt_outlined,
                    ),
                    _buildImagePickerSection(),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      'INFORMASI UTAMA',
                      Icons.inventory_2_outlined,
                    ),
                    _buildTextField(
                      label: 'Nama Barang',
                      hintText: 'Misal: Meja Belajar Kayu',
                      controller: _nameController,
                      validator:
                          (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      label: 'Kode Barang (Otomatis)',
                      hintText: 'Akan terisi otomatis',
                      controller: _codeController,
                      enabled: false,
                    ),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      'DETAIL STOK & UNIT',
                      Icons.analytics_outlined,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildQuantityField()),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            label: 'Satuan',
                            hintText: 'Pcs/Box',
                            controller: _unitController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildConditionDropdown(),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      'LOKASI PENYIMPANAN',
                      Icons.location_on_outlined,
                    ),
                    _buildLocationSelector(),
                    const SizedBox(height: 32),

                    _buildSectionHeader(
                      'KETERANGAN TAMBAHAN',
                      Icons.description_outlined,
                    ),
                    _buildTextField(
                      label: 'Deskripsi',
                      hintText: 'Tambahkan catatan jika perlu...',
                      controller: _descriptionController,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24), // Reduced spacing
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0085FF)),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0085FF),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0085FF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child:
              _isSaving
                  ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Text(
                    widget.item == null ? 'Simpan Inventaris' : 'Perbarui Data',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return GestureDetector(
      onTap: _showImageSourcePicker,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100, width: 1.5),
        ),
        child:
            _imageFile != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(_imageFile!, fit: BoxFit.cover),
                )
                : (widget.item?.imageUrl != null &&
                    widget.item!.imageUrl!.isNotEmpty)
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(
                    imageUrl: widget.item!.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.grey,
                    ),
                  ),
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_a_photo_outlined,
                        size: 28,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tambahkan Foto Barang',
                      style: GoogleFonts.poppins(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Gunakan kamera atau galeri',
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildQuantityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jumlah',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              _buildSmallSquareButton(
                icon: Icons.remove,
                onTap: () {
                  int current = int.tryParse(_quantityController.text) ?? 0;
                  if (current > 0) {
                    _quantityController.text = (current - 1).toString();
                  }
                },
              ),
              Expanded(
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              _buildSmallSquareButton(
                icon: Icons.add,
                onTap: () {
                  int current = int.tryParse(_quantityController.text) ?? 0;
                  _quantityController.text = (current + 1).toString();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallSquareButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFFF1F3F4),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.black87, size: 18),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: enabled ? Colors.black87 : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          enabled: enabled,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: enabled ? Colors.black87 : Colors.grey.shade600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF1F3F4),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF0085FF),
                width: 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade100),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lokasi',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isLoadingLocations ? null : _showLocationPicker,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _selectedLocation?.name ??
                        (_isLoadingLocations
                            ? 'Memuat lokasi...'
                            : 'Pilih Lokasi'),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight:
                          _selectedLocation == null
                              ? FontWeight.normal
                              : FontWeight.w600,
                      color:
                          _selectedLocation == null
                              ? Colors.grey
                              : Colors.black87,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kondisi Barang',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _conditionController.text,
          items:
              ['Baik', 'Rusak Ringan', 'Rusak Berat']
                  .map(
                    (label) => DropdownMenuItem(
                      value: label,
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _conditionController.text = value);
            }
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF0085FF),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
