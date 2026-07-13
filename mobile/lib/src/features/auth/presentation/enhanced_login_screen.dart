import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'providers/auth_provider.dart';
import '../domain/models/user_model.dart';
import '../../../services/firebase_auth_service.dart';
import '../../../providers/language_provider.dart';
import '../../../widgets/language_selector_widget.dart';

class EnhancedLoginScreen extends StatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  State<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends State<EnhancedLoginScreen> with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _usePhone = true;
  bool _showExtraFields = false;
  String _selectedRole = 'farmer'; // farmer or officer
  
  late AnimationController _logoAnimationController;
  late AnimationController _cardAnimationController;

  @override
  void initState() {
    super.initState();
    _logoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _logoAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Quick Demo Login - Direct access to dashboard
  Future<void> _demoLogin() async {
    setState(() => _isLoading = true);
    
    final authProvider = context.read<AuthProvider>();
    
    // Create demo user based on selected role
    final demoUser = User(
      userId: 'demo_${_selectedRole}_${DateTime.now().millisecondsSinceEpoch}',
      name: _selectedRole == 'officer' ? 'Demo Officer' : 'Demo Farmer',
      email: _selectedRole == 'officer' ? 'officer@krashibandhu.com' : 'demo@krashibandhu.com',
      phone: '+919876543210',
      role: _selectedRole,
    );
    
    authProvider.setDemoUser(demoUser);
    
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
    
    if (mounted) {
      _showSuccess('✅ Demo Login Successful!');
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        // Navigate based on role
        if (_selectedRole == 'officer') {
          context.go('/officer-dashboard');
        } else {
          context.go('/dashboard');
        }
      }
    }
  }

  Future<void> _sendOTP() async {
    String input = _usePhone ? _phoneController.text.trim() : _emailController.text.trim();
    
    if (_usePhone) {
      if (input.length != 10) {
        _showError('कृपया 10 अंकों का मोबाइल नंबर दर्ज करें');
        return;
      }
    } else {
      if (!input.contains('@')) {
        _showError('Please enter a valid email address');
        return;
      }
    }

    setState(() => _isLoading = true);

    if (_usePhone) {
      final phoneNumber = '+91${_phoneController.text}';
      
      try {
        final firebaseAuth = context.read<FirebaseAuthService>();
        
        await firebaseAuth.sendOTP(
          phoneNumber,
          (message) {
            setState(() {
              _otpSent = true;
              _isLoading = false;
            });
            _showSuccess('✅ OTP sent to your mobile number');
          },
          (error) {
            setState(() => _isLoading = false);
            _showError('❌ Failed to send OTP: $error');
          },
        );
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Error: $e');
      }
    } else {
      setState(() => _isLoading = false);
      _showError('Email OTP not configured yet. Please use phone login.');
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      _showError('कृपया 6 अंकों का OTP दर्ज करें');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseAuth = context.read<FirebaseAuthService>();
      final credential = await firebaseAuth.verifyOTP(_otpController.text);
      
      if (credential != null && credential.user != null) {
        final user = credential.user!;
        final authProvider = context.read<AuthProvider>();
        
        final newUser = User(
          userId: user.uid,
          name: _nameController.text.trim().isEmpty 
              ? 'User ${_phoneController.text}' 
              : _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty 
              ? '${user.phoneNumber}@pmfby.app' 
              : _emailController.text.trim(),
          phone: user.phoneNumber ?? '+91${_phoneController.text}',
          role: 'farmer',
        );
        
        authProvider.setDemoUser(newUser);
        
        setState(() => _isLoading = false);
        
        if (mounted) {
          _showSuccess('✅ Login successful! Redirecting...');
          
          // Use Navigator.pushReplacement for guaranteed navigation
          await Future.delayed(const Duration(milliseconds: 800));
          
          if (mounted) {
            // Navigate based on role
            try {
              if (_selectedRole == 'officer') {
                context.go('/officer-dashboard');
              } else {
                context.go('/dashboard');
              }
            } catch (e) {
              // Fallback to pushReplacement if go fails
              Navigator.of(context).pushReplacementNamed(
                _selectedRole == 'officer' ? '/officer-dashboard' : '/dashboard',
              );
            }
          }
        }
      } else {
        setState(() => _isLoading = false);
        _showError('❌ OTP verification failed. Please try again.');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('❌ Invalid OTP. Please try again.');
      debugPrint('OTP Verification Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // PMFBY Background - Full Screen Consistent
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/OVERALLBACKGROUND.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              repeat: ImageRepeat.noRepeat,
              errorBuilder: (context, error, stackTrace) {
                // Try alternate background
                return Image.asset(
                  'assets/images/background.jpg',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  repeat: ImageRepeat.noRepeat,
                  errorBuilder: (ctx, err, stack) {
                    // Fallback gradient background
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.green.shade50,
                            Colors.amber.shade50,
                            Colors.green.shade100,
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Transparent Gradient Overlay - PMFBY Style
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  colors: [
                    Colors.white.withOpacity(0.80),  // Top - app bar area
                    Colors.white.withOpacity(0.65),  // Upper content
                    Colors.white.withOpacity(0.70),  // Lower content
                    Colors.white.withOpacity(0.80),  // Bottom - footer area
                  ],
                ),
              ),
            ),
          ),
          
          // Main Content Container
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                      // Language Selector at top
                      Align(
                        alignment: Alignment.topRight,
                        child: const LanguageSelectorWidget(showAsButton: true),
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 20),

                      // Farmer Avatar with Wheat Background
                      Center(
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.9),
                            border: Border.all(
                              color: Colors.green.shade300.withOpacity(0.6),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade300.withOpacity(0.4),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/avatars/Avtar2.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Try alternate avatar
                                return Image.asset(
                                  'assets/images/avatars/AVTAR1.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) {
                                    return Icon(
                                      Icons.agriculture,
                                      size: 70,
                                      color: Colors.green.shade700,
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 30),

                      // App Name with Animation
                      Consumer<LanguageProvider>(
                        builder: (context, langProvider, child) {
                          return FutureBuilder<String>(
                            future: langProvider.translate('Krishi Bandhu'),
                            builder: (context, snapshot) {
                              return Text(
                                snapshot.data ?? 'Krishi Bandhu',
                                style: GoogleFonts.poppins(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.8),
                                      offset: const Offset(0, 2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3, end: 0);
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 12),

                      Consumer<LanguageProvider>(
                        builder: (context, langProvider, child) {
                          return FutureBuilder<String>(
                            future: langProvider.translate('Farmer Login'),
                            builder: (context, snapshot) {
                              return Text(
                                '${snapshot.data ?? 'Farmer Login'} | किसान लॉगिन',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade800,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withOpacity(0.9),
                                      offset: const Offset(0, 1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 40),

                      // Login Card
                      _buildLoginCard(),

                      const SizedBox(height: 30),

                      // Help Text
                      _buildHelpCard(),

                      const SizedBox(height: 20),

                      // New Farmer Registration Link
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/register/farmer'),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.green.shade800,
                              ),
                              children: [
                                const TextSpan(text: 'नए किसान हैं? | New Farmer? '),
                                TextSpan(
                                  text: 'पंजीकरण करें | Register Now',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Officer Registration Link
                      Center(
                        child: TextButton(
                          onPressed: () => context.go('/register/officer'),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.indigo.shade800,
                              ),
                              children: [
                                const TextSpan(text: 'नए अधिकारी हैं? | New Officer? '),
                                TextSpan(
                                  text: 'पंजीकरण करें | Register Now',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo.shade700,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Footer
                      Text(
                        'PMFBY - Pradhan Mantri Fasal Bima Yojana',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ).animate().fadeIn(delay: 800.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88), // PMFBY style - more opaque
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.green.shade300.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade200.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Consumer<LanguageProvider>(
            builder: (context, langProvider, child) {
              return FutureBuilder<String>(
                future: langProvider.translate(_otpSent ? 'Enter OTP' : 'Login'),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? (_otpSent ? 'OTP दर्ज करें' : 'Login करें'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  );
                },
              );
            },
          ).animate().fadeIn(duration: 400.ms).scale(),

          const SizedBox(height: 28),

          if (!_otpSent) ..._buildPhoneInputFields() else ..._buildOTPFields(),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideY(begin: 0.3, end: 0);
  }

  List<Widget> _buildPhoneInputFields() {
    return [
      // Toggle between Phone and Email
      Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              icon: Icons.phone_android,
              label: '📱 Phone',
              isSelected: _usePhone,
              onTap: () => setState(() => _usePhone = true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildToggleButton(
              icon: Icons.email,
              label: '📧 Email',
              isSelected: !_usePhone,
              onTap: () => setState(() => _usePhone = false),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.2, end: 0),
      
      const SizedBox(height: 24),

      // Phone or Email Input
      if (_usePhone)
        _buildPhoneField()
      else
        _buildEmailField(),
      
      const SizedBox(height: 20),

      // Extra Fields Toggle
      _buildExtraFieldsToggle(),

      if (_showExtraFields) ...[
        const SizedBox(height: 16),
        _buildNameField(),
        if (_usePhone) ...[
          const SizedBox(height: 16),
          _buildEmailField(),
        ],
      ],

      const SizedBox(height: 28),

      // Send OTP Button
      _buildSendOTPButton(),
      
      const SizedBox(height: 20),
      
      // Role Selector
      _buildRoleSelector(),
      
      const SizedBox(height: 16),
      
      // Demo Login Button - Quick Access
      _buildDemoLoginButton(),
    ];
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.green.shade400 : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.green.shade900 : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: 'मोबाइल नंबर | Mobile Number',
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(Icons.phone, color: Colors.green.shade700),
        prefixText: '+91 ',
        prefixStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        hintText: '9876543210',
        filled: true,
        fillColor: Colors.green.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2.5),
        ),
        counterText: '',
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(
        labelText: _usePhone ? 'Email (Optional)' : 'Email Address',
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(Icons.email, color: Colors.green.shade700),
        hintText: 'farmer@example.com',
        filled: true,
        fillColor: Colors.green.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2.5),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      style: GoogleFonts.poppins(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'नाम | Name (Optional)',
        labelStyle: GoogleFonts.poppins(),
        prefixIcon: Icon(Icons.person, color: Colors.green.shade700),
        hintText: 'Ram Kumar',
        filled: true,
        fillColor: Colors.green.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2.5),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildExtraFieldsToggle() {
    return TextButton.icon(
      onPressed: () {
        setState(() => _showExtraFields = !_showExtraFields);
      },
      icon: AnimatedRotation(
        turns: _showExtraFields ? 0.25 : 0,
        duration: const Duration(milliseconds: 300),
        child: Icon(
          Icons.chevron_right,
          color: Colors.green.shade700,
        ),
      ),
      label: Text(
        _showExtraFields ? 'Hide Details' : 'अधिक जानकारी | Add Details (Optional)',
        style: GoogleFonts.poppins(
          color: Colors.green.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSendOTPButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _sendOTP,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
        shadowColor: Colors.green.shade300,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send, size: 20),
                const SizedBox(width: 12),
                Text(
                  'OTP भेजें | Send OTP',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
    ).animate().fadeIn(delay: 400.ms).scale();
  }

  Widget _buildRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Login as | के रूप में लॉगिन करें',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildRoleButton(
                role: 'farmer',
                icon: Icons.agriculture,
                label: 'Farmer | किसान',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRoleButton(
                role: 'officer',
                icon: Icons.admin_panel_settings,
                label: 'Officer | अधिकारी',
                color: Colors.indigo,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleButton({
    required String role,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label.split('|')[0].trim(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoLoginButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade400.withOpacity(0.15),
            Colors.green.shade400.withOpacity(0.15),
          ],
        ),
        border: Border.all(
          color: Colors.green.shade400.withOpacity(0.6),
          width: 2,
        ),
      ),
      child: OutlinedButton(
        onPressed: _isLoading ? null : _demoLogin,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.green.shade800,
          backgroundColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flash_on, size: 22, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Text(
              'Quick Demo Login | डेमो लॉगिन',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  List<Widget> _buildOTPFields() {
    return [
      Icon(
        Icons.mark_email_read,
        size: 64,
        color: Colors.green.shade600,
      ).animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: 2000.ms, color: Colors.green.shade200),
      
      const SizedBox(height: 20),

      Text(
        'OTP आपके ${_usePhone ? "मोबाइल" : "ईमेल"} पर भेजा गया है',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: Colors.green.shade800,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ).animate().fadeIn(delay: 200.ms),

      const SizedBox(height: 24),

      // OTP Input
      TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        autofocus: true,
        style: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: 16,
          color: Colors.green.shade900,
        ),
        decoration: InputDecoration(
          hintText: '● ● ● ● ● ●',
          hintStyle: TextStyle(color: Colors.grey.shade400),
          filled: true,
          fillColor: Colors.green.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade200, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.green.shade600, width: 3),
          ),
          counterText: '',
        ),
      ).animate().fadeIn(delay: 300.ms).scale(),

      const SizedBox(height: 28),

      // Verify Button
      ElevatedButton(
        onPressed: _isLoading ? null : _verifyOTP,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'सत्यापित करें | Verify',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ).animate().fadeIn(delay: 400.ms).scale(),

      const SizedBox(height: 16),

      // Resend OTP
      TextButton.icon(
        onPressed: _isLoading ? null : () {
          setState(() => _otpSent = false);
          _otpController.clear();
        },
        icon: Icon(Icons.refresh, color: Colors.green.shade700),
        label: Text(
          'OTP दोबारा भेजें | Resend OTP',
          style: GoogleFonts.poppins(
            color: Colors.green.shade700,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ).animate().fadeIn(delay: 500.ms),
    ];
  }

  Widget _buildHelpCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'सुरक्षित और आसान लॉगिन\nSecure & Easy Login',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.white.withOpacity(0.95),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0);
  }
}
