import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/inventory_location_model.dart';

class LocationTreePicker extends StatefulWidget {
  final List<InventoryLocationModel> locations;
  final int? selectedLocationId;
  final Function(InventoryLocationModel) onSelected;

  const LocationTreePicker({
    super.key,
    required this.locations,
    this.selectedLocationId,
    required this.onSelected,
  });

  @override
  State<LocationTreePicker> createState() => _LocationTreePickerState();
}

class _LocationTreePickerState extends State<LocationTreePicker> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.locations.length,
      itemBuilder: (context, index) {
        return _buildLocationNode(widget.locations[index], 0);
      },
    );
  }

  Widget _buildLocationNode(InventoryLocationModel location, int depth) {
    final bool hasChildren = location.children.isNotEmpty;
    final bool isSelected = location.id == widget.selectedLocationId;

    if (!hasChildren) {
      return ListTile(
        contentPadding: EdgeInsets.only(left: 16.0 + (depth * 16.0)),
        title: Text(
          location.name,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF0085FF) : Colors.black87,
          ),
        ),
        trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF0085FF)) : null,
        onTap: () => widget.onSelected(location),
      );
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.only(left: 16.0 + (depth * 16.0), right: 16.0),
      title: Text(
        location.name,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? const Color(0xFF0085FF) : Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) const Icon(Icons.check, color: Color(0xFF0085FF), size: 18),
          const SizedBox(width: 8),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
      children: location.children.map((child) => _buildLocationNode(child, depth + 1)).toList(),
      onExpansionChanged: (expanded) {
        // If user taps the tile itself (not the expand arrow), we might want to select it
        // But usually ExpansionTile expands on tap. 
        // We can add a "Select this location" button inside if needed, 
        // or just allow selecting any node.
      },
    );
  }
}
