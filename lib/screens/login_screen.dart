import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _authService = AuthService();
  final _biometricService = BiometricService();

  bool _isLoading = false;
  bool _isObscure = true;
  bool _isBiometricSupported = false;
  bool _hasSavedCredentials = false;

  // Institutional Color Palette
  static const Color _primaryNavy = Color(0xFF1F3C88);
  static const Color _brandBlue = Color(0xFF2563EB);
  static const Color _scaffoldBg = Color(0xFFF8FAFC);
  static const Color _textMain = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _borderSoft = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final isSupported = await _biometricService.isDeviceSupported();
    final credentials = await _biometricService.getCredentials();
    if (mounted) {
      setState(() {
        _isBiometricSupported = isSupported;
        _hasSavedCredentials = credentials != null;
      });
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan masukkan email dan password',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.login(email, password);

    if (result.success) {
      await _biometricService.saveCredentials(email, password);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message,
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: const Color(0xFFE11D48),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (!_hasSavedCredentials) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan login manual sekali untuk mengaktifkan biometrik',
            style: GoogleFonts.poppins(fontSize: 13),
          ),
          backgroundColor: _brandBlue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final authenticated = await _biometricService.authenticate();
      if (authenticated) {
        final credentials = await _biometricService.getCredentials();
        if (credentials != null) {
          _emailController.text = credentials['email']!;
          _passwordController.text = credentials['password']!;
          _handleLogin();
        }
      } else {
        final isSupported = await _biometricService.isDeviceSupported();
        if (!isSupported && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Biometrik belum didukung atau belum didaftarkan di perangkat ini.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: const Color(0xFFD97706),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan biometrik: $e',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
            backgroundColor: const Color(0xFFE11D48),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: AutofillGroup(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- 1. HEADER INSTITUSI ---
                  Container(
                    width: 88,
                    height: 88,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: _borderSoft, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aplikasi YAC',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _textMain,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yayasan As-Sunnah Cirebon',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textMuted,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- 2. CARD FORM LOGIN ---
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _borderSoft),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF0F172A,
                          ).withValues(alpha: 0.05),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Masuk ke Akun',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Gunakan email terdaftar untuk mengakses aplikasi.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _textMuted,
                          ),
                        ),
                        const SizedBox(height: 22),

                        // --- FIELD EMAIL ---
                        Text(
                          'Email',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [
                            AutofillHints.email,
                            AutofillHints.username,
                          ],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _textMain,
                          ),
                          decoration: InputDecoration(
                            hintText: 'nama@email.com',
                            hintStyle: GoogleFonts.poppins(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.mail_outline_rounded,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _borderSoft),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _primaryNavy,
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        // --- FIELD PASSWORD ---
                        Text(
                          'Kata Sandi',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _isObscure,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.password],
                          onFieldSubmitted: (_) => _handleLogin(),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: _textMain,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Masukkan kata sandi',
                            hintStyle: GoogleFonts.poppins(
                              color: const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 20,
                              color: Color(0xFF64748B),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure = !_isObscure;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: _borderSoft),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: _primaryNavy,
                                width: 1.6,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- TOMBOL MASUK ---
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child:
                                _isLoading
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      'Masuk',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                          ),
                        ),

                        // --- OPSIONAL: BIOMETRIC LOGIN ---
                        if (_isBiometricSupported) ...[
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  'atau',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(color: Color(0xFFE2E8F0)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed:
                                  _isLoading ? null : _handleBiometricLogin,
                              icon: Icon(
                                Icons.fingerprint_rounded,
                                size: 22,
                                color:
                                    _hasSavedCredentials
                                        ? _primaryNavy
                                        : const Color(0xFF94A3B8),
                              ),
                              label: Text(
                                _hasSavedCredentials
                                    ? 'Masuk dengan Biometrik'
                                    : 'Biometrik (Login manual dulu)',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      _hasSavedCredentials
                                          ? _primaryNavy
                                          : const Color(0xFF94A3B8),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color:
                                      _hasSavedCredentials
                                          ? _primaryNavy.withValues(alpha: 0.3)
                                          : _borderSoft,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor:
                                    _hasSavedCredentials
                                        ? _primaryNavy.withValues(alpha: 0.03)
                                        : Colors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
