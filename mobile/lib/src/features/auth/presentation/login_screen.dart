import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import '../domain/models/user_model.dart';
import '../../../utils/demo_users.dart';
import '../../../services/firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
// ---------------------------
// CONTROLLERS
// ---------------------------
final _phoneController = TextEditingController();
final _otpController = TextEditingController();
final _emailController = TextEditingController();
final _nameController = TextEditingController();

// ---------------------------
// STATE
// ---------------------------
bool _isLoading = false;
bool _otpSent = false;
bool _usePhone = true; // Default to phone login
bool _showEmailField = false;

@override
void dispose() {
  _phoneController.dispose();
  _otpController.dispose();
  _emailController.dispose();
  _nameController.dispose();
  super.dispose();
}

// ---------------------------
// COMMON SNACKBAR HELPERS
// ---------------------------
void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.red),
  );
}

void _showSuccess(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: Colors.green),
  );
}

// =====================================================
// PHONE OTP LOGIN - FIREBASE
// =====================================================
Future<void> _sendOTP() async {
  String input = _usePhone 
      ? _phoneController.text.trim() 
      : _emailController.text.trim();
  
  if (_usePhone) {
    // Phone validation
    if (input.length != 10) {
      _showError('कृपया 10 अंकों का मोबाइल नंबर दर्ज करें');
      return;
    }
  } else {
    // Email validation
    if (!input.contains('@')) {
      _showError('Please enter a valid email address');
      return;
    }
  }

  setState(() => _isLoading = true);

  if (_usePhone) {
    // Firebase Phone Authentication
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
          _showSuccess('OTP sent to your mobile number');
        },
        (error) {
          setState(() => _isLoading = false);
          _showError('Failed to send OTP: $error');
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error: $e');
    }
  } else {
    // For email, we'll use existing email OTP service or demo
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
    
    if (credential != null) {
      // Successfully authenticated with Firebase
      final user = credential.user;
      
      if (user != null) {
        // Create or update user in our system
        final authProvider = context.read<AuthProvider>();
        
        // Create user model (default as farmer)
        final newUser = User(
          userId: user.uid,
          name: _nameController.text.trim().isEmpty 
              ? 'User ${_phoneController.text}' 
              : _nameController.text.trim(),
          email: _emailController.text.trim().isEmpty 
              ? '${user.phoneNumber}@pmfby.app' 
              : _emailController.text.trim(),
          phone: user.phoneNumber ?? '+91${_phoneController.text}',
          role: 'farmer', // Default role
        );
        
        authProvider.setDemoUser(newUser);
        
        if (mounted) {
          _showSuccess('Login successful!');
          // Direct to farmer dashboard
          context.go('/dashboard');
        }
      }
    }
  } catch (e) {
    setState(() => _isLoading = false);
    _showError('Invalid OTP. Please try again.');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.green.shade700,
              Colors.green.shade400,
              Colors.lightGreen.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // LOGO
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.agriculture,
                      size: 80,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // APP NAME
                  Text(
                    'Krishi Bandhu',
                    style: GoogleFonts.poppins(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text(
                    'किसान लॉगिन | Farmer Login',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // LOGIN CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Title
                        Text(
                          _otpSent ? 'OTP दर्ज करें | Enter OTP' : 'Login करें',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 24),

                        if (!_otpSent) ...[
                          // Toggle between Phone and Email
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: Text('📱 Phone'),
                                selected: _usePhone,
                                onSelected: (selected) {
                                  setState(() => _usePhone = true);
                                },
                                selectedColor: Colors.green.shade100,
                              ),
                              const SizedBox(width: 12),
                              ChoiceChip(
                                label: Text('📧 Email'),
                                selected: !_usePhone,
                                onSelected: (selected) {
                                  setState(() => _usePhone = false);
                                },
                                selectedColor: Colors.green.shade100,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Phone or Email Input
                          if (_usePhone) ...[
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: 'मोबाइल नंबर | Mobile Number',
                                prefixIcon: const Icon(Icons.phone, size: 24),
                                prefixText: '+91 ',
                                hintText: '9876543210',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade300, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade200, width: 2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                ),
                                counterText: '',
                              ),
                            ),
                          ] else ...[
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: const Icon(Icons.email, size: 24),
                                hintText: 'farmer@example.com',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade300, width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade200, width: 2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Optional Name Field (Collapsible)
                          TextButton.icon(
                            onPressed: () {
                              setState(() => _showEmailField = !_showEmailField);
                            },
                            icon: Icon(
                              _showEmailField ? Icons.remove_circle_outline : Icons.add_circle_outline,
                              color: Colors.green.shade700,
                            ),
                            label: Text(
                              'अधिक जानकारी | Add Details (Optional)',
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),

                          if (_showEmailField) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'नाम | Name (Optional)',
                                prefixIcon: const Icon(Icons.person),
                                hintText: 'Ram Kumar',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            if (_usePhone) ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email (Optional)',
                                  prefixIcon: const Icon(Icons.email),
                                  hintText: 'farmer@example.com',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ],

                          const SizedBox(height: 24),

                          // Send OTP Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _sendOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'OTP भेजें | Send OTP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ] else ...[
                          // OTP Input
                          Text(
                            'OTP आपके ${_usePhone ? "मोबाइल" : "ईमेल"} पर भेजा गया है',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              labelText: 'OTP',
                              hintText: '● ● ● ● ● ●',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.green.shade300, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.green.shade200, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                              ),
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Verify Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _verifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'सत्यापित करें | Verify',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),

                          // Resend OTP
                          TextButton(
                            onPressed: _isLoading ? null : () {
                              setState(() => _otpSent = false);
                              _otpController.clear();
                            },
                            child: Text(
                              'OTP दोबारा भेजें | Resend OTP',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'अपने मोबाइल नंबर से लॉगिन करें\nLogin with your mobile number',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'PMFBY - Pradhan Mantri Fasal Bima Yojana',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
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
