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
  final _authService = AuthService();
  final _biometricService = BiometricService();
  bool _isLoading = false;
  bool _isObscure = true;
  bool _canUseBiometrics = false;

  // Colors based on the logo/blue theme requested
  final Color _primaryBlue = const Color(0xFF1F3C88);

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final canUse = await _biometricService.canUseBiometrics();
    if (mounted) {
      setState(() {
        _canUseBiometrics = canUse;
      });
    }
    // Optional: Auto trigger if already has credentials
    if (canUse && _emailController.text.isEmpty) {
      // Future.delayed(const Duration(milliseconds: 500), _handleBiometricLogin);
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan email dan password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _authService.login(email, password);

    if (result.success) {
      // Save credentials for future biometric login
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
        SnackBar(content: Text(result.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleBiometricLogin() async {
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
        // Authenticate returned false (failed or cancelled)
        final isSupported = await _biometricService.isDeviceSupported();
        if (!isSupported && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Biometrik belum didukung atau belum didaftarkan di perangkat ini.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan biometrik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Base Background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),

          // 2. Modern Gradient Orbs (Aurora Effect)
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFF1F3C88,
                    ).withValues(alpha: 0.2), // Primary Blue
                    const Color(0xFF1F3C88).withValues(alpha: 0.0),
                  ],
                  radius: 0.6,
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(
                      0xFF3F51B5,
                    ).withValues(alpha: 0.15), // Lighter Indigo
                    const Color(0xFF3F51B5).withValues(alpha: 0.0),
                  ],
                  radius: 0.6,
                  stops: const [0.0, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.1),
                    Colors.blueAccent.withValues(alpha: 0.0),
                  ],
                  radius: 0.5,
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // LOGO & TITLE
                    Image.asset('assets/images/logo.png', height: 80),
                    const SizedBox(height: 16),
                    Text(
                      'Aplikasi YAC',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // WHITE CARD
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // USER IDENTITY INPUT
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Masukkan Email',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // PASSWORD INPUT
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // "Forgot?" Removed per "remove ... need hel[p]" general simplification or just keeping it clean as requested?
                              // User specifically asked to remove "touchid" and "need hel".
                              // "Forgot?" is usually part of password field in the visual, I will add it as a dummy text for visual match.
                              // Text(
                              //   'Forgot?',
                              //   style: GoogleFonts.poppins(
                              //     fontSize: 12,
                              //     fontWeight: FontWeight.bold,
                              //     color: _primaryBlue,
                              //   ),
                              // ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _isObscure,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.grey[400],
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscure
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.grey[400],
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscure = !_isObscure;
                                    });
                                  },
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // SIGN IN & BIOMETRIC BUTTON
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryBlue,
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
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : Text(
                                              'Masuk',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                              if (_canUseBiometrics) ...[
                                const SizedBox(width: 12),
                                Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.fingerprint_rounded,
                                      color: _primaryBlue,
                                      size: 32,
                                    ),
                                    onPressed:
                                        _isLoading
                                            ? null
                                            : _handleBiometricLogin,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ), // End SafeArea
        ],
      ),
    );
  }
}
