import sys

file_path = r'c:\src\Project\dashboard-yac\lib\screens\dashboard_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Line 470 in previous view was '      }'
# Line 471 was empty
# Line 472 was '      if (_locations.isEmpty) {'

# We want to replace from line 470 to where the broken method ends.
# But wait, let's just find the markers.

start_marker = '      if (mounted) setState(() => _isLoadingActivity = false);\n'
# We want to keep this line, then close the finally, the try, and the method.

new_content = []
found = False
for line in lines:
    new_content.append(line)
    if start_marker in line and not found:
        found = True
        # Close the finally block, the try-catch, and the _fetchDashboardData method
        new_content.append("    }\n")
        new_content.append("  }\n")
        new_content.append("\n")
        # Add the restored _handleAttendance method
        new_content.append("  // --- LOGIC 3: EKSEKUSI ABSEN ---\n")
        new_content.append("  Future<void> _handleAttendance() async {\n")
        new_content.append("    if (_attendanceStatus == \"SELESAI\") return;\n")
        new_content.append("\n")
        new_content.append("    // --- INTEGRASI IZIN ---\n")
        new_content.append("    // Jika status BELUM_ABSEN (mau masuk), cek apakah ada izin harian yang sudah disetujui hari ini\n")
        new_content.append("    if (_attendanceStatus == \"BELUM_ABSEN\") {\n")
        new_content.append("      _showLoadingSnackBar(\"Memeriksa status izin...\");\n")
        new_content.append("      final hasPermit = await PermitService().hasApprovedFullDayPermitToday(int.parse(_userId));\n")
        new_content.append("      \n")
        new_content.append("      if (!mounted) return;\n")
        new_content.append("      ScaffoldMessenger.of(context).clearSnackBars();\n")
        new_content.append("\n")
        new_content.append("      if (hasPermit) {\n")
        new_content.append("        _showErrorDialog(\n")
        new_content.append("          \"Anda tidak dapat melakukan absensi masuk karena hari ini Anda tercatat sedang izin/cuti (Full Day) yang telah disetujui.\",\n")
        new_content.append("        );\n")
        new_content.append("        return;\n")
        new_content.append("      }\n")
        new_content.append("    }\n")
        new_content.append("\n")
        new_content.append("    // 1. Flow Berdasarkan Status\n")
        new_content.append("    if (_attendanceStatus == \"BELUM_ABSEN\" ||\n")
        new_content.append("        _attendanceStatus == \"SUDAH_MASUK\") {\n")
        new_content.append("      // Check-in & Check-out flow: Sekarang keduanya butuh pilih lokasi\n")
        new_content.append("      if (_locations.isEmpty) {\n")
        new_content.append("        _showLoadingSnackBar(\"Mengambil data lokasi...\");\n")
        new_content.append("        await _fetchLocations();\n")
        new_content.append("        if (!mounted) return;\n")
        new_content.append("        ScaffoldMessenger.of(context).clearSnackBars();\n")
        new_content.append("      }\n")
        
        # Now we need to skip the redundant/broken lines in the original file
        # The original file had 'if (_locations.isEmpty) {' at line 472 (which is now index 471)
        # So we skip everything until we find 'if (_locations.isEmpty) {' and then skip THAT line too.
        pass

# This is still a bit complex. Let's just use a simpler approach:
# Replace the range of lines that are broken.

final_lines = []
skip = False
for i in range(len(lines)):
    if 'if (mounted) setState(() => _isLoadingActivity = false);' in lines[i]:
        final_lines.append(lines[i])
        final_lines.append("    }\n")
        final_lines.append("  }\n")
        final_lines.append("\n")
        final_lines.append("  // --- LOGIC 3: EKSEKUSI ABSEN ---\n")
        final_lines.append("  Future<void> _handleAttendance() async {\n")
        final_lines.append("    if (_attendanceStatus == \"SELESAI\") return;\n")
        final_lines.append("\n")
        final_lines.append("    // --- INTEGRASI IZIN ---\n")
        final_lines.append("    if (_attendanceStatus == \"BELUM_ABSEN\") {\n")
        final_lines.append("      _showLoadingSnackBar(\"Memeriksa status izin...\");\n")
        final_lines.append("      final hasPermit = await PermitService().hasApprovedFullDayPermitToday(int.parse(_userId));\n")
        final_lines.append("      if (!mounted) return;\n")
        final_lines.append("      ScaffoldMessenger.of(context).clearSnackBars();\n")
        final_lines.append("      if (hasPermit) {\n")
        final_lines.append("        _showErrorDialog(\"Anda tidak dapat melakukan absensi masuk karena hari ini Anda tercatat sedang izin/cuti (Full Day) yang telah disetujui.\");\n")
        final_lines.append("        return;\n")
        final_lines.append("      }\n")
        final_lines.append("    }\n")
        final_lines.append("\n")
        final_lines.append("    if (_attendanceStatus == \"BELUM_ABSEN\" || _attendanceStatus == \"SUDAH_MASUK\") {\n")
        final_lines.append("      if (_locations.isEmpty) {\n")
        final_lines.append("        _showLoadingSnackBar(\"Mengambil data lokasi...\");\n")
        final_lines.append("        await _fetchLocations();\n")
        final_lines.append("        if (!mounted) return;\n")
        final_lines.append("        ScaffoldMessenger.of(context).clearSnackBars();\n")
        final_lines.append("      }\n")
        skip = True
        continue
    
    if skip:
        if 'if (_locations.isEmpty) {' in lines[i]:
            # Found the start of the next valid block, stop skipping
            skip = False
            continue # skip this line as we already added it
        else:
            continue
            
    final_lines.append(lines[i])

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(final_lines)
