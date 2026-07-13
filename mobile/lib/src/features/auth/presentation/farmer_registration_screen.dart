import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/language_provider.dart';
import '../../../services/firebase_auth_service.dart';

/// Enhanced Farmer Registration Screen with PMFBY Fields
/// किसान पंजीकरण स्क्रीन - OTP, Mobile, Name, Village, Town
class FarmerRegistrationScreen extends StatefulWidget {
  const FarmerRegistrationScreen({super.key});

  @override
  State<FarmerRegistrationScreen> createState() => _FarmerRegistrationScreenState();
}

class _FarmerRegistrationScreenState extends State<FarmerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _villageController = TextEditingController();
  final _townController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _showPassword = false;
  
  String? _verificationId;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _villageController.dispose();
    _townController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image - Wheat Field
          _buildBackgroundImage(),
          
          // Gradient Overlay - Transparent
          _buildGradientOverlay(),
          
          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Farmer Avatar
                      _buildFarmerAvatar(),
                      
                      const SizedBox(height: 24),
                      
                      // Title
                      _buildTitle(),
                      
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      _buildSubtitle(),
                      
                      const SizedBox(height: 32),
                      
                      // Registration Form Card
                      _buildRegistrationCard(),
                      
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      _buildSubmitButton(),
                      
                      const SizedBox(height: 16),
                      
                      // Already Registered? Login
                      _buildLoginLink(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundImage() {
    return Positioned.fill(
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
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.3, 0.7, 1.0],
            colors: [
              Colors.white.withOpacity(0.80),  // Top - more opaque for header
              Colors.white.withOpacity(0.65),  // Upper-mid - lighter
              Colors.white.withOpacity(0.70),  // Lower-mid - balanced
              Colors.white.withOpacity(0.80),  // Bottom - more opaque for footer
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFarmerAvatar() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade300.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/images/avatars/farmer_avatar.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.person,
                size: 60,
                color: Colors.green.shade700,
              );
            },
          ),
        ),
      )
          .animate()
          .scale(duration: 600.ms, curve: Curves.elasticOut)
          .fadeIn(duration: 400.ms),
    );
  }

  Widget _buildTitle() {
    return Text(
      'किसान पंजीकरण\nFarmer Registration',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.green.shade900,
        height: 1.3,
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildSubtitle() {
    return Text(
      'PMFBY बीमा के लिए अपना विवरण दर्ज करें\nEnter your details for PMFBY insurance',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: Colors.green.shade800,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildRegistrationCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88), // PMFBY style - consistent opacity
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
          // Farmer Name
          _buildTextField(
            controller: _nameController,
            label: 'किसान का नाम | Farmer Name',
            hint: 'अपना पूरा नाम दर्ज करें',
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'कृपया अपना नाम दर्ज करें';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Mobile Number
          _buildTextField(
            controller: _phoneController,
            label: 'मोबाइल नंबर | Mobile Number',
            hint: '10 अंकों का मोबाइल नंबर',
            icon: Icons.phone_android,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'कृपया मोबाइल नंबर दर्ज करें';
              }
              if (value.length != 10) {
                return 'मोबाइल नंबर 10 अंकों का होना चाहिए';
              }
              return null;
            },
            suffixWidget: !_isOtpSent
                ? TextButton(
                    onPressed: _sendOTP,
                    child: Text(
                      'OTP भेजें',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  )
                : Icon(
                    Icons.check_circle,
                    color: Colors.green.shade600,
                    size: 24,
                  ),
          ),
          
          // OTP Field (shown after OTP sent)
          if (_isOtpSent) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _otpController,
              label: 'OTP कोड | OTP Code',
              hint: '6 अंकों का OTP',
              icon: Icons.security,
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'कृपया OTP दर्ज करें';
                }
                if (value.length != 6) {
                  return 'OTP 6 अंकों का होना चाहिए';
                }
                return null;
              },
              suffixWidget: TextButton(
                onPressed: _sendOTP,
                child: Text(
                  'फिर भेजें',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.2, end: 0),
          ],
          
          const SizedBox(height: 16),
          
          // Village
          _buildTextField(
            controller: _villageController,
            label: 'गांव | Village',
            hint: 'अपना गांव दर्ज करें',
            icon: Icons.home_outlined,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'कृपया गांव का नाम दर्ज करें';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Town/Tehsil
          _buildTextField(
            controller: _townController,
            label: 'शहर/तहसील | Town/Tehsil',
            hint: 'शहर या तहसील दर्ज करें',
            icon: Icons.location_city_outlined,
            keyboardType: TextInputType.text,
          ),
          
          const SizedBox(height: 16),
          
          // District
          _buildTextField(
            controller: _districtController,
            label: 'जिला | District',
            hint: 'अपना जिला दर्ज करें',
            icon: Icons.map_outlined,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'कृपया जिला दर्ज करें';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // State
          _buildTextField(
            controller: _stateController,
            label: 'राज्य | State',
            hint: 'अपना राज्य दर्ज करें',
            icon: Icons.flag_outlined,
            keyboardType: TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'कृपया राज्य दर्ज करें';
              }
              return null;
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 500.ms).slideY(begin: 0.3, end: 0);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
    Widget? suffixWidget,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.green.shade800,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.green.shade900,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.green.shade400,
            ),
            prefixIcon: Icon(icon, color: Colors.green.shade600, size: 22),
            suffixIcon: suffixWidget,
            counterText: '',
            filled: true,
            fillColor: Colors.white.withOpacity(0.7),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade300.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green.shade600, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        shadowColor: Colors.green.shade300.withOpacity(0.5),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 24),
                const SizedBox(width: 12),
                Text(
                  'पंजीकरण करें | Register Now',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
    ).animate().fadeIn(delay: 500.ms, duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget _buildLoginLink() {
    return Center(
      child: TextButton(
        onPressed: () {
          context.go('/login');
        },
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.green.shade800,
            ),
            children: [
              const TextSpan(text: 'पहले से पंजीकृत हैं? | Already registered? '),
              TextSpan(
                text: 'लॉगिन करें | Login',
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
    );
  }

  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty || _phoneController.text.length != 10) {
      _showError('कृपया सही मोबाइल नंबर दर्ज करें');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final phoneNumber = '+91${_phoneController.text}';
      final authService = FirebaseAuthService();

      await authService.sendOTP(
        phoneNumber,
        (message) {
          if (mounted) {
            setState(() {
              _isOtpSent = true;
              _isLoading = false;
            });
            _showSuccess('OTP आपके मोबाइल पर भेजा गया है');
          }
        },
        (error) {
          if (mounted) {
            _showError('सत्यापन विफल: $error');
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        _showError('त्रुटि: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Save farmer details directly without OTP
      final farmerData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'village': _villageController.text,
        'town': _townController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'registeredAt': DateTime.now().toIso8601String(),
      };

      print('Farmer registered: $farmerData');

      if (mounted) {
        _showSuccess('पंजीकरण सफल! आप अब लॉगिन कर सकते हैं');
        
        // Navigate to dashboard
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('पंजीकरण विफल: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
