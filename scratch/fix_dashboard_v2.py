import sys

file_path = r'c:\src\Project\dashboard-yac\lib\screens\dashboard_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_content = []
skip_start = -1
skip_end = -1

for i, line in enumerate(lines):
    if '// --- LOGIC 3: EKSEKUSI ABSEN ---' in line:
        skip_start = i
    if 'Future<void> _handleAttendanceWithGPS' in line:
        skip_end = i
        break

if skip_start != -1 and skip_end != -1:
    # Replace everything between skip_start and skip_end
    replacement = [
        "  // --- LOGIC 3: EKSEKUSI ABSEN ---\n",
        "  Future<void> _handleAttendance() async {\n",
        "    if (_attendanceStatus == \"SELESAI\") return;\n",
        "\n",
        "    // --- INTEGRASI IZIN ---\n",
        "    if (_attendanceStatus == \"BELUM_ABSEN\") {\n",
        "      _showLoadingSnackBar(\"Memeriksa status izin...\");\n",
        "      final hasPermit = await PermitService().hasApprovedFullDayPermitToday(int.parse(_userId));\n",
        "      if (!mounted) return;\n",
        "      ScaffoldMessenger.of(context).clearSnackBars();\n",
        "      if (hasPermit) {\n",
        "        _showErrorDialog(\"Anda tidak dapat melakukan absensi masuk karena hari ini Anda tercatat sedang izin/cuti (Full Day) yang telah disetujui.\");\n",
        "        return;\n",
        "      }\n",
        "    }\n",
        "\n",
        "    if (_attendanceStatus == \"BELUM_ABSEN\" || _attendanceStatus == \"SUDAH_MASUK\") {\n",
        "      if (_locations.isEmpty) {\n",
        "        _showLoadingSnackBar(\"Mengambil data lokasi...\");\n",
        "        await _fetchLocations();\n",
        "        if (!mounted) return;\n",
        "        ScaffoldMessenger.of(context).clearSnackBars();\n",
        "      }\n",
        "\n",
        "      if (_locations.isEmpty) {\n",
        "        _showSnackBar(\n",
        "          message: \"Data lokasi kantor tidak tersedia\",\n",
        "          isError: true,\n",
        "        );\n",
        "        return;\n",
        "      }\n",
        "\n",
        "      if (_locations.length == 1) {\n",
        "        _handleAttendanceWithGPS(_locations.first);\n",
        "      } else {\n",
        "        _showLocationPicker();\n",
        "      }\n",
        "    }\n",
        "  }\n",
        "\n"
    ]
    
    lines[skip_start:skip_end] = replacement

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(lines)
