import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../core/api_constants.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _fullName = '';
  String _email = '';
  String _unitName = ''; // Used as Role
  String _divisionName = '';
  String _positionName = '';
  String _phoneNumber = '';
  String _address = '';
  String _profilePhoto = '';
  int _positionLevel = 99;
  bool _pushNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    setState(() {
      _fullName = prefs.getString('fullName') ?? 'User Name';
      _email = prefs.getString('email') ?? 'user@email.com';
      _unitName = prefs.getString('unitName') ?? ''; // Empty default
      _divisionName = prefs.getString('divisionName') ?? '';
      _positionName = prefs.getString('positionName') ?? '';
      _phoneNumber = prefs.getString('phoneNumber') ?? '';
      _address = prefs.getString('address') ?? '';
      _profilePhoto = prefs.getString('profilePhoto') ?? '';
      _positionLevel = prefs.getInt('positionLevel') ?? 99;
    });

    // Debug: Print loaded data
    debugPrint('📋 Profile Data Loaded:');
    debugPrint('   Full Name: $_fullName');
    debugPrint('   Position Name: $_positionName');
    debugPrint('   Position Level: $_positionLevel');
    debugPrint('   Unit Name: $_unitName');
    debugPrint('   Division Name: $_divisionName');
    debugPrint('   Address: $_address');
  }

  /// Returns the position to display in the badge
  /// Falls back to level-based position names if positionName is empty
  String _getDisplayPosition() {
    // If positionName exists, use it directly
    if (_positionName.isNotEmpty) {
      return _positionName;
    }

    // Fallback based on position level for supervisors/managers
    // Level hierarchy: 1 = Mudir, 2 = Kepala Bidang, 3 = Kepala Unit, 4 = Guru/Musyrif, 5 = Staf
    if (_positionLevel == 1) {
      return 'Mudir';
    } else if (_positionLevel == 2) {
      return 'Kepala Bidang';
    } else if (_positionLevel == 3) {
      return 'Kepala Unit';
    } else if (_positionLevel == 4) {
      return 'Guru';
    } else if (_positionLevel == 5) {
      return 'Staf';
    }

    // If no positionName and positionLevel is default (99 or null),
    // all employee data is likely not filled in database
    // Return generic fallback
    return 'Karyawan';
  }

  String _getDisplayRole() {
    // Logic: If unitName is available, show it (Staff).
    // If unitName is empty (Manager/Head), show Division Name.
    if (_unitName.isNotEmpty) {
      return _unitName;
    }

    // Fallback for managers who don't have a unit but have a division
    if (_divisionName.isNotEmpty) {
      return _divisionName;
    }

    return ''; // Hide if no info available
  }

  Future<void> _handleLogout() async {
    final authService = AuthService();
    await authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Profil',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => EditProfileScreen(
                                fullName: _fullName,
                                email: _email,
                                phoneNumber: _phoneNumber,
                                address: _address,
                                profilePhoto: _profilePhoto,
                              ),
                        ),
                      );
                      _loadUserData();
                    },
                    child: Text(
                      'Ubah',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Profile Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: Colors.blueAccent,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child:
                                () {
                                  final photoUrl = ApiConstants.getProfilePhotoUrl(_profilePhoto);
                                  return (photoUrl != null && photoUrl.isNotEmpty)
                                      ? CachedNetworkImage(
                                        key: ValueKey(photoUrl),
                                        imageUrl: photoUrl,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) =>
                                            const SizedBox(
                                              width: 48,
                                              height: 48,
                                              child:
                                                  CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                  ),
                                            ),
                                        errorWidget: (context, url, error) =>
                                            const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            ),
                                      )
                                      : const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      );
                                }(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _fullName,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Position Badge - Always shown with fallback
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0085FF), // Corporate Blue
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getDisplayPosition(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_getDisplayRole().isNotEmpty)
                      Text(
                        _getDisplayRole(),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('INFORMASI KONTAK'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildInfoTile(
                      icon: Icons.email,
                      iconColor: Colors.blueAccent,
                      title: 'Alamat Email',
                      subtitle: _email,
                    ),
                    const Divider(height: .5),
                    _buildInfoTile(
                      icon: Icons.phone,
                      iconColor: Colors.green,
                      title: 'NomorTelepon',
                      subtitle: _phoneNumber.isEmpty ? '-' : _phoneNumber,
                    ),
                    const Divider(height: .5),
                    _buildInfoTile(
                      icon: Icons.business,
                      iconColor: Colors.purple,
                      title: 'Bidang',
                      subtitle: _divisionName,
                    ),
                    const Divider(height: .5),
                    _buildInfoTile(
                      icon: Icons.location_on,
                      iconColor: Colors.orange,
                      title: 'Alamat',
                      subtitle: _address.isEmpty ? '-' : _address,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('KEAMANAN'),
              const SizedBox(height: 12),
              _buildActionTile(
                icon: Icons.lock_outline,
                iconColor: const Color(0xFF3B82F6),
                title: 'Ubah Kata Sandi',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('PENGATURAN APLIKASI'),
              const SizedBox(height: 12),
              _buildSwitchTile(
                icon: Icons.notifications_none,
                iconColor: Colors.orange,
                title: 'Notifikasi',
                value: _pushNotifications,
                onChanged: (val) {
                  setState(() {
                    _pushNotifications = val;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildActionTile(
                icon: Icons.help_outline,
                iconColor: const Color(0xFF64748B),
                title: 'Bantuan & Dukungan',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Keluar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Versi 1.0.0 (Build 001)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Made with ❤ by Abu Aufar',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    bool showArrow = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing:
          showArrow
              ? const Icon(Icons.chevron_right, color: Colors.grey)
              : null,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.blueAccent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.withValues(alpha: 0.4),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
